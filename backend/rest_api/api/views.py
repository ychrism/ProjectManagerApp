from rest_framework import viewsets
from .models import Board, Card, TheUser, Message
from .serializers import BoardSerializer, CardSerializer, TheUserSerializer, SignInSerializer, MessageSerializer
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from .permissions import *
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db import IntegrityError
from django.db.models import Max, Subquery, OuterRef, Q
from rest_framework.exceptions import ValidationError, PermissionDenied
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from rest_framework.decorators import action
from uuid import uuid4
from django.core.cache import cache



class SignInView(TokenObtainPairView):
    serializer_class = SignInSerializer

class SignupView(generics.CreateAPIView):
    queryset = TheUser.objects.all()
    permission_classes = (AllowAny,)

    def post(self, request, *args, **kwargs):
        first_name = request.data.get('first_name')
        last_name = request.data.get('last_name')
        password = request.data.get('password')
        email = request.data.get('email')

        try:
            user = TheUser.objects.create_user(first_name=first_name, last_name=last_name, password=password, email=email)
            user.save()

            return Response({"msg": "User created successfully"}, status=status.HTTP_201_CREATED)
        except IntegrityError as e:
            if 'email' in str(e):
                return Response({"err": "Email already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": "Failed to create user"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class BoardViewSet(viewsets.ModelViewSet):
    permission_classes = [IsMemberOfBoardOrAdmin]
    queryset = Board.objects.all()
    serializer_class = BoardSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            return Board.objects.all()
        return Board.objects.filter(members__in=[user])

    def create(self, request, *args, **kwargs):
        try:
            board = super().create(request, *args, **kwargs)
            return Response(BoardSerializer(board.data).data, status=status.HTTP_201_CREATED)
        except PermissionDenied as e:
            return Response({"err": str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            if 'name' in str(e):
                return Response({"err": "Board name already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": "Failed to create board"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)
            pass

    def update(self, request, *args, **kwargs):
        try:
            response = super().update(request, *args, **kwargs)
            return Response(response.data)
        except PermissionDenied as e:
            return Response({"err": str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            if 'name' in str(e):
                return Response({"err": "Board name already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)



class CardViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrCardMember]
    serializer_class = CardSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            queryset = Card.objects.all()
        else:
            queryset = Card.objects.filter(members__in=[user])

        board_id = self.request.query_params.get('board', None)
        if board_id is not None:
            queryset = queryset.filter(board_id=board_id)
        return queryset

    def create(self, request, *args, **kwargs):
        try:
            response = super().create(request, *args, **kwargs)
            self.update_board_progress(response.data['board_details']['id'])
            return response
        except PermissionDenied as e:
            return Response({"err": str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            if 'title' in e.detail:
                return Response({"err": "Card title already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        try:
            response = super().update(request, *args, **kwargs)
            self.update_board_progress(response.data['board_details']['id'])
            return response
        except PermissionDenied as e:
            return Response({"err": str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValidationError as e:
            if 'title' in str(e):
                return Response({"err": "Card title already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": "Failed to update card"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def perform_create(self, serializer):
        card = serializer.save()
        self.update_board_members(card)

    def perform_update(self, serializer):
        card = serializer.save()
        self.update_board_members(card)


    def update_board_members(self, card):
        board = card.board
        # Get all cards for this board
        board_cards = Card.objects.filter(board=board)
        
        # Get all users who are members of any card in this board
        card_members = set()
        for board_card in board_cards:
            card_members.update(board_card.members.all())
        
        # Update the board's members
        board.members.set(card_members)
        board.save()

    def update_board_progress(self, board_id):
        board = Board.objects.get(id=board_id)
        total_cards = Card.objects.filter(board=board).count()
        completed_cards = Card.objects.filter(board=board, status='DONE').count()
        
        if total_cards > 0:
            progress = (completed_cards / total_cards) * 100
        else:
            progress = 0
        
        board.progress = round(progress, 2)
        board.save()



class TheUserViewSet(viewsets.ModelViewSet):
    queryset = TheUser.objects.all()
    serializer_class = TheUserSerializer

    @action(detail=False, methods=['GET'], permission_classes=[IsAuthenticated])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)


class MessageViewSet(viewsets.ModelViewSet):
    permission_classes = [IsBoardMemberOrAdminForMessage]
    queryset = Message.objects.all()
    serializer_class = MessageSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_admin:
            queryset = Message.objects.all()
        else:
            queryset = Message.objects.filter(board__members__in=[user])

        board_id = self.request.query_params.get('board', None)
        if board_id is not None:
            queryset = queryset.filter(board_id=board_id)
        return queryset


    @action(detail=False, methods=['GET'])
    def latest_messages(self, request):
        try:
            user = request.user
            if user.is_admin:
                board_ids = Board.objects.values_list('id', flat=True)
            else:
                board_ids = Board.objects.filter(members__in=[user]).values_list('id', flat=True)
            
            latest_messages = []
            
            for board_id in board_ids:
                latest_message = Message.objects.filter(board_id=board_id).order_by('-date_sent').first()
                if latest_message:
                    latest_messages.append(latest_message)
            
            serializer = self.get_serializer(latest_messages, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)





class AsgiValidateTokenView(APIView):
    """
        get:
            API view for retrieving ticket to connect to websocket .
    """

    def get(self, request, *args, **kwargs):
        
        ticket_uuid = uuid4()
        user_id = request.user.id
        cache_key = f"websocket_auth:{ticket_uuid}"
        cache.set(cache_key, user_id, 86400) # timeout 24h

        return Response({'uuid': ticket_uuid})
