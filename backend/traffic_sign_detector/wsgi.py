"""
WSGI config for traffic_sign_detector project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'traffic_sign_detector.settings')

application = get_wsgi_application() 