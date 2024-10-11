"""
ASGI config for rest_api project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""
"""
ASGI config for rest_api project.
It exposes the ASGI callable as a module-level variable named `application`.
For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""

import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from api.middleware import JwtAuthMiddlewareStack
from channels.security.websocket import AllowedHostsOriginValidator


os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rest_api.settings')
http_response_app = get_asgi_application()

import api.routing

application = ProtocolTypeRouter({
    "http": http_response_app,
    "websocket": AllowedHostsOriginValidator(
            JwtAuthMiddlewareStack(
                URLRouter(api.routing.websocket_urlpatterns)
            )
    ),
})