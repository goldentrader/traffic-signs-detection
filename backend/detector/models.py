from django.db import models
from django.utils import timezone
from django.contrib.auth.models import User


class Detection(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='detections', null=True, blank=True)
    timestamp = models.DateTimeField(default=timezone.now)
    image = models.ImageField(upload_to='detections/', null=True, blank=True)
    detections_count = models.IntegerField(default=0)
    confidence_avg = models.FloatField(default=0.0)
    processing_time = models.FloatField(default=0.0)  # in seconds
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        user_info = f" - {self.user.username}" if self.user else ""
        return f"Detection {self.id}{user_info} - {self.timestamp}"


class DetectionResult(models.Model):
    detection = models.ForeignKey(Detection, on_delete=models.CASCADE, related_name='results')
    class_name = models.CharField(max_length=100)
    confidence = models.FloatField()
    bbox_x = models.FloatField()  # normalized coordinates
    bbox_y = models.FloatField()
    bbox_width = models.FloatField()
    bbox_height = models.FloatField()
    
    def __str__(self):
        return f"{self.class_name} ({self.confidence:.2f})" 