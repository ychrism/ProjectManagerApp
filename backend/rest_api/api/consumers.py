import json 
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Board, Message, TheUser
import logging
from datetime import datetime
from django.core.serializers.json import DjangoJSONEncoder
from django.db.models.fields.files import FieldFile
from django.utils.timezone import is_aware
from asgiref.sync import async_to_sync

logger = logging.getLogger(__name__)

class CombinedEncoder(DjangoJSONEncoder):
    def default(self, obj):
        if isinstance(obj, FieldFile):
            try:
                return obj.url
            except ValueError:
                return None
        elif isinstance(obj, datetime):
            if is_aware(obj):
                obj = obj.astimezone()
            return obj.isoformat()
        return super().default(obj)

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        logger.info(f"Connect attempt received from: {self.scope['path']}")
        self.board_id = self.scope['url_route']['kwargs'].get('board_id')
        
        if self.board_id:
            self.board_name = f"board_{self.board_id}"
            await self.channel_layer.group_add(self.board_name, self.channel_name)
        
        await self.accept()

    async def disconnect(self, close_code):
        logger.info(f"Disconnected with code: {close_code}")
        if self.board_id:
            await self.channel_layer.group_discard(self.board_name, self.channel_name)


    async def receive(self, text_data):
        logger.info("New data received")
        data_json = json.loads(text_data)
        
        # Create the message once
        new_message = await self.create_message(data_json)
        
        # Prepare the message data
        message_data = await self.prepare_message_data(new_message)
        
        # Send to the specific board group
        if self.board_id:
            await self.channel_layer.group_send(
                self.board_name,
                {
                    "type": "chat_message",
                    "message": message_data
                }
            )
    

    async def chat_message(self, event):
        message = event['message']
        await self.send(text_data=json.dumps(message, cls=CombinedEncoder))


    @database_sync_to_async
    def create_message(self, data):
        board = Board.objects.get(id=data['board'])
        user = TheUser.objects.get(id=data['sent_by'])
        new_message = Message.objects.create(board=board, sent_by=user, content=data['content'])
        return new_message

    @database_sync_to_async
    def prepare_message_data(self, message):
        return {
            'id': message.id,
            'board': message.board.to_dict(),
            'sent_by': message.sent_by.to_dict(),
            'content': message.content,
            'date_sent': message.date_sent.isoformat()
        }


class MessageHomeConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        self.user_group = f"user_{self.user.id}_latest_messages"
        print(f"New connection attempt from {self.user.id}")

        # Join user-specific group
        await self.channel_layer.group_add(self.user_group, self.channel_name)

        await self.accept()

    async def disconnect(self, close_code):
        # Leave user-specific group
        await self.channel_layer.group_discard(self.user_group, self.channel_name)

    async def receive(self, text_data):
        # We don't expect to receive messages from the client in this consumer
        pass

    async def latest_message_update(self, event):
        # Send message to WebSocket
        await self.send(text_data=json.dumps(event['message'], cls=CombinedEncoder))


class EchoConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        self.n = 0
        await self.accept()
        await self.send(text_data=json.dumps({'message': 'Connected'}))

    async def receive(self, text_data):
        self.n += 1
        text_data_json = json.loads(text_data)
        message = text_data_json['message']
        print(f"Received message: {message}")
        
        response = f"Echo {self.n}: {message}"
        await self.send(text_data=json.dumps({'message': response}))

    async def disconnect(self, close_code):
        print(f"Disconnected with code: {close_code}")