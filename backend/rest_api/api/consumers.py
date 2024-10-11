import json 
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Board, Message, TheUser
import logging
from datetime import datetime
from django.core.serializers.json import DjangoJSONEncoder
from django.db.models.fields.files import FieldFile
from django.contrib.auth.models import AnonymousUser
from django.utils.timezone import is_aware
from asgiref.sync import async_to_sync
from urllib.parse import parse_qsl
from channels.exceptions import StopConsumer
from django.core.cache import cache

logger = logging.getLogger('api')

# Date and image fields json encoder used when sending message to connected clients.
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
        self.board_id = self.scope['url_route']['kwargs'].get('board_id')
        self.user = self.scope['user']

        if isinstance(self.user, AnonymousUser):
            #logger.warning(f"Connection attempt rejected for anonymous user on {self.scope['path']}")
            await self.close()
        else:
            # Parse query string to get UUID
            query_string = self.scope['query_string'].decode("utf-8")
            query_params = dict(parse_qsl(query_string))
            uuid = query_params.get('uuid')
            self.cache_key = f"websocket_auth:{uuid}"

            if self.board_id:
                self.board_name = f"board_{self.board_id}"
                await self.channel_layer.group_add(self.board_name, self.channel_name)


            # logger.info(f"Connection accepted for user {self.user.id} on {self.scope['path']}")
            await self.accept()

    async def disconnect(self, close_code):
        # logger.info(f"[User {self.scope['user'].id}] {self.scope['path']} - Disconnected with code: {close_code}")
        if getattr(self, 'board_name', False):
            await self.channel_layer.group_discard(self.board_name, self.channel_name)

        # Delete the cache entry when the user disconnects
        if hasattr(self, 'cache_key'):
            cache.delete(self.cache_key)
        
        # Raise StopConsumer to properly close the consumer
        raise StopConsumer()
        
    async def receive(self, text_data):
        logger.debug(f"{self.scope['path']} - New data received")
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

# Consumer to automatically send TO-DO task to DOING when time is up.
class CardTaskConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        self.board_id = self.scope['url_route']['kwargs'].get('board_id')
        
        if isinstance(self.user, AnonymousUser):
            #logger.warning(f"Connection attempt rejected for anonymous user on {self.scope['path']}")
            await self.close()
        else:
            # Parse query string to get UUID
            query_string = self.scope['query_string'].decode("utf-8")
            query_params = dict(parse_qsl(query_string))
            uuid = query_params.get('uuid')
            self.cache_key = f"websocket_auth:{uuid}"

            if self.board_id:
                self.board_name = f"board_{self.board_id}"
                await self.channel_layer.group_add(self.board_name, self.channel_name)
            
            # logger.info(f"Connection accepted for user {self.user.id} on {self.scope['path']}")
            await self.accept()

    async def disconnect(self, close_code):
        # logger.info(f"[User {self.scope['user'].id}] {self.scope['path']} - Disconnected with code: {close_code}")
        if getattr(self, 'board_name', False):
            await self.channel_layer.group_discard(self.board_name, self.channel_name)
        
        # Delete the cache entry when the user disconnects
        if hasattr(self, 'cache_key'):
            cache.delete(self.cache_key)
        
        # Raise StopConsumer to properly close the consumer
        raise StopConsumer()

    async def receive(self, text_data):
        # We don't expect to receive messages from the client in this consumer
        pass

    async def card_status_update(self, event):
        # Send message to WebSocket
        logger.debug(f"{self.scope['path']} - sending new event")
        await self.send(text_data=json.dumps(event, cls=CombinedEncoder))

# Message home consumer to allow connected clients to receive in real time new messages without need to enter in single chat 
# Users alone in their group. Their own inbox everywhere connected different from simple self.channel_name
class MessageHomeConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        
        if isinstance(self.user, AnonymousUser):
            # logger.warning(f"Connection attempt rejected for anonymous user on {self.scope['path']}")
            await self.close()
        else:
            # Parse query string to get UUID
            query_string = self.scope['query_string'].decode("utf-8")
            query_params = dict(parse_qsl(query_string))
            uuid = query_params.get('uuid')
            self.cache_key = f"websocket_auth:{uuid}"

            self.user_group = f"user_{self.user.id}_latest_messages"
            # Join user-specific group
            await self.channel_layer.group_add(self.user_group, self.channel_name)

            # logger.info(f"Connection accepted on {self.scope['path']}")
            await self.accept()

    async def disconnect(self, close_code):
        # logger.info(f"{self.scope['path']} - Disconnected with code: {close_code}")
        # Leave user-specific group
        if getattr(self, 'user_group', False):
            await self.channel_layer.group_discard(self.user_group, self.channel_name)
        
        # Delete the cache entry when the user disconnects
        if hasattr(self, 'cache_key'):
            cache.delete(self.cache_key)
        
        # Raise StopConsumer to properly close the consumer
        raise StopConsumer()

    async def receive(self, text_data):
        # We don't expect to receive messages from the client in this consumer
        pass

    async def latest_message_update(self, event):
        # Send message to WebSocket
        logger.debug(f"{self.scope['path']} - sending new event")
        await self.send(text_data=json.dumps(event, cls=CombinedEncoder))


# Test consumer to echo sent message
class EchoConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        self.n = 0
        self.user = self.scope['user']

        if isinstance(self.user, AnonymousUser):
            # logger.warning(f"Connection attempt rejected for anonymous user on {self.scope['path']}")
            await self.close()
        else:
            # Parse query string to get UUID
            query_string = self.scope['query_string'].decode("utf-8")
            query_params = dict(parse_qsl(query_string))
            uuid = query_params.get('uuid')
            self.cache_key = f"websocket_auth:{uuid}"

            # logger.info(f"Connection accepted on {self.scope['path']}")
            await self.accept()
            await self.send(text_data=json.dumps({'message': 'Connected'}))

    async def receive(self, text_data):
        self.n += 1
        text_data_json = json.loads(text_data)
        message = text_data_json['message']
        logger.debug(f"{self.scope['path']} - Received message: {message}")
        
        response = f"Echo {self.n}: {message}"
        await self.send(text_data=json.dumps({'message': response}))

    async def disconnect(self, close_code):
        # logger.info(f"[User {self.scope['user'].id }] {self.scope['path']} - Disconnected with code: {close_code}")
        
        # Delete the cache entry when the user disconnects
        if hasattr(self, 'cache_key'):
            cache.delete(self.cache_key)
        
        # Raise StopConsumer to properly close the consumer
        raise StopConsumer()