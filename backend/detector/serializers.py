from rest_framework import serializers
from .models import Detection, DetectionResult


class DetectionResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = DetectionResult
        fields = ['class_name', 'confidence', 'bbox_x', 'bbox_y', 'bbox_width', 'bbox_height']


class DetectionSerializer(serializers.ModelSerializer):
    results = DetectionResultSerializer(many=True, read_only=True)
    
    class Meta:
        model = Detection
        fields = ['id', 'timestamp', 'image', 'detections_count', 'confidence_avg', 'processing_time', 'results'] 