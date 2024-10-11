from channels.db import database_sync_to_async
from urllib.parse import parse_qsl
from channels.middleware import BaseMiddleware
from channels.auth import AuthMiddlewareStack
from django.db import close_old_connections
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
import logging
from django.core.cache import cache

logger = logging.getLogger('api')
User = get_user_model()


@database_sync_to_async
def get_user(user_id):
    try:
        return User.objects.get(id=user_id)
    except User.DoesNotExist:
        logger.warning(f"User with id {user_id} not found")
        return AnonymousUser()

class JwtAuthMiddleware(BaseMiddleware):
    def __init__(self, app):
        self.app = app

    async def auth(self, query_string):
        query_params = dict(parse_qsl(query_string))
        uuid = query_params.get('uuid') # getting uuid from request query url parameters string
        
        if not uuid:
            logger.warning("No UUID provided in query string")
            return AnonymousUser()

        cache_key = f"websocket_auth:{uuid}"
        user_id = cache.get(cache_key)

        if user_id is None:
            logger.warning(f"UUID not found in cache")
            return AnonymousUser()

        return await get_user(user_id)

    async def __call__(self, scope, receive, send):
        # Close old database connections to prevent usage of timed out connections
        close_old_connections()

        if scope["type"] == "websocket":
            query_string = scope.get('query_string', b'').decode('utf-8')
            user = await self.auth(query_string)
            scope['user'] = user

        return await self.app(scope, receive, send)

def JwtAuthMiddlewareStack(inner):
    return JwtAuthMiddleware(AuthMiddlewareStack(inner))