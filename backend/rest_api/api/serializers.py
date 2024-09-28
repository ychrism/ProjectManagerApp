from rest_framework import serializers
from .models import Board, Card, TheUser
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class SignInSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Add custom claims if needed
        token['email'] = user.email
        return token

    def validate(self, attrs):
        # Use email to authenticate instead of username
        user = TheUser.objects.filter(email=attrs.get("email")).first()
        if user is not None:
            attrs["username"] = user.email  # trick the default behavior
        return super().validate(attrs)

class TheUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = TheUser
        fields =  ['first_name', 'last_name', 'email']


class BoardSerializer(serializers.ModelSerializer):
    members = TheUserSerializer(many=True, read_only=True)
    
    class Meta:
        model = Board
        fields = '__all__'


class CardSerializer(serializers.ModelSerializer):
    board =  serializers.PrimaryKeyRelatedField(queryset=Board.objects.all(), write_only=True)
    board_details = BoardSerializer(source='board', read_only=True)
    members = TheUserSerializer(many=True, read_only=True)

    # This is an extra field not in the model, used only for input
    emails = serializers.ListField(
        child=serializers.EmailField(),
        write_only=True,  # Only used during creation/updating, not displayed in the response
        required=False
    )

    class Meta:
        model = Card
        fields = ['id', 'title', 'priority', 'status', 'start_date', 'due_date', 'board', 'board_details', 'description', 'members', 'emails']  # Matching the Card model fields

    
    def create(self, validated_data):
        emails = validated_data.pop('emails', [])
        members = TheUser.objects.filter(email__in=emails)
        card = Card.objects.create(**validated_data)
        card.members.set(members)
        return card

    def update(self, instance, validated_data):
        emails = validated_data.pop('emails', [])
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        if len(emails) != 0:
            members = TheUser.objects.filter(email__in=emails)
            instance.members.set(members)
        
        instance.save()
        return instance



