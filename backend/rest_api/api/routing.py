from django.urls import re_path
from .consumers import *

websocket_urlpatterns = [
    re_path(r"^ws/chat/(?P<board_id>\w+)/$", ChatConsumer.as_asgi()),
    re_path(r'ws/latest_message_update/$', MessageHomeConsumer.as_asgi()),
    re_path(r'ws/echo/$', EchoConsumer.as_asgi())
]