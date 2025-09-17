"""
ASGI config for traffic_sign_detector project.
"""

import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import detector.routing

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'traffic_sign_detector.settings')

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(
            detector.routing.websocket_urlpatterns
        )
    ),
}) 