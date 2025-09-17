from django.urls import path
from . import views

urlpatterns = [
    path('detect/', views.detect_image, name='detect_image'),
    path('detections/', views.get_detections, name='get_detections'),
    path('stats/', views.get_detection_stats, name='get_detection_stats'),
    path('global-stats/', views.get_global_stats, name='get_global_stats'),
] 