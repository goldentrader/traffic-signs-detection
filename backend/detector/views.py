from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from .models import Detection, DetectionResult
from .serializers import DetectionSerializer
from .yolo_detector import YOLODetector
import base64
import io
from PIL import Image
import json
from django.db import models


# Initialize detector instance
detector = YOLODetector()


@api_view(['POST'])
@permission_classes([IsAuthenticatedOrReadOnly])
def detect_image(request):
    """
    API endpoint for single image detection
    """
    try:
        data = json.loads(request.body)
        base64_image = data.get('image')
        
        if not base64_image:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Run detection
        result = detector.detect_from_base64(base64_image)
        
        if 'error' in result:
            return Response({'error': result['error']}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Save detection to database (only if user is authenticated)
        user = request.user if request.user.is_authenticated else None
        detection = Detection.objects.create(
            user=user,
            detections_count=result['detections_count'],
            confidence_avg=result['confidence_avg'],
            processing_time=result['processing_time']
        )
        
        # Save detection results
        for det in result['detections']:
            DetectionResult.objects.create(
                detection=detection,
                class_name=det['class_name'],
                confidence=det['confidence'],
                bbox_x=det['bbox_x'],
                bbox_y=det['bbox_y'],
                bbox_width=det['bbox_width'],
                bbox_height=det['bbox_height']
            )
        
        # Serialize and return
        serializer = DetectionSerializer(detection)
        return Response({
            'detection': serializer.data,
            'detections': result['detections'],
            'processing_time': result['processing_time']
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_detections(request):
    """
    Get user's detection history
    """
    detections = Detection.objects.filter(user=request.user)[:50]  # Last 50 detections
    serializer = DetectionSerializer(detections, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_detection_stats(request):
    """
    Get user's detection statistics
    """
    try:
        user_detections = Detection.objects.filter(user=request.user)
        total_detections = user_detections.count()
        
        if total_detections == 0:
            return Response({
                'total_detections': 0,
                'avg_processing_time': 0,
                'avg_confidence': 0,
                'most_detected_signs': []
            })
        
        # Calculate average processing time
        avg_processing_time = user_detections.aggregate(
            avg_time=models.Avg('processing_time')
        )['avg_time'] or 0
        
        # Calculate average confidence
        avg_confidence = user_detections.aggregate(
            avg_conf=models.Avg('confidence_avg')
        )['avg_conf'] or 0
        
        # Get most detected signs for this user
        from django.db.models import Count
        most_detected = DetectionResult.objects.filter(
            detection__user=request.user
        ).values('class_name').annotate(
            count=Count('class_name')
        ).order_by('-count')[:5]
        
        return Response({
            'total_detections': total_detections,
            'avg_processing_time': round(avg_processing_time, 3),
            'avg_confidence': round(avg_confidence, 3),
            'most_detected_signs': list(most_detected)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticatedOrReadOnly])
def get_global_stats(request):
    """
    Get global detection statistics (for dashboard)
    """
    try:
        if request.user.is_authenticated:
            # Return user-specific stats if authenticated
            return get_detection_stats(request)
        else:
            # Return limited global stats for anonymous users
            total_detections = Detection.objects.count()
            
            if total_detections == 0:
                return Response({
                    'total_detections': 0,
                    'avg_processing_time': 0,
                    'avg_confidence': 0,
                    'most_detected_signs': []
                })
            
            # Calculate global averages
            avg_processing_time = Detection.objects.aggregate(
                avg_time=models.Avg('processing_time')
            )['avg_time'] or 0
            
            avg_confidence = Detection.objects.aggregate(
                avg_conf=models.Avg('confidence_avg')
            )['avg_conf'] or 0
            
            # Get most detected signs globally
            from django.db.models import Count
            most_detected = DetectionResult.objects.values('class_name').annotate(
                count=Count('class_name')
            ).order_by('-count')[:5]
            
            return Response({
                'total_detections': total_detections,
                'avg_processing_time': round(avg_processing_time, 3),
                'avg_confidence': round(avg_confidence, 3),
                'most_detected_signs': list(most_detected)
            })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR) 