from rest_framework import viewsets
from .models import Board, Card, TheUser
from .serializers import BoardSerializer, CardSerializer, TheUserSerializer, SignInSerializer
from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .permissions import *
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db import IntegrityError
from rest_framework.exceptions import ValidationError



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

    def create(self, request, *args, **kwargs):
        try:
            board = super().create(request, *args, **kwargs)
            return Response(BoardSerializer(board.data).data, status=status.HTTP_201_CREATED)
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
        except ValidationError as e:
            if 'name' in str(e):
                return Response({"err": "Board name already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class CardViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminOrCardMember]
    queryset = Card.objects.all()
    serializer_class = CardSerializer

    def create(self, request, *args, **kwargs):
        try:
            card = super().create(request, *args, **kwargs)
            self.update_board_members(card.data)
            return Response(CardSerializer(card.data).data, status=status.HTTP_201_CREATED)
        except ValidationError as e:
            if 'title' in str(e):
                return Response({"err": "Card title already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": "Failed to create card"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        try:
            card = self.get_object()
            old_members = set(card.members.all())
            update_fields = request.data.keys()
            
            updated_card = super().update(request, *args, **kwargs)
            
            if 'emails' not in update_fields:
                updated_card.data.members.set(old_members)
            
            self.update_board_members(updated_card.data)
            return Response(CardSerializer(updated_card.data).data)
        except ValidationError as e:
            if 'title' in str(e):
                return Response({"err": "Card title already exists"}, status=status.HTTP_400_BAD_REQUEST)
            return Response({"err": "Failed to update card"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"err": str(e)}, status=status.HTTP_400_BAD_REQUEST)


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



class TheUserViewSet(viewsets.ModelViewSet):
    queryset = TheUser.objects.all()
    serializer_class = TheUserSerializer