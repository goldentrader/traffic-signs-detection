from django.contrib import admin
from .models import Detection, DetectionResult


class DetectionResultInline(admin.TabularInline):
    model = DetectionResult
    extra = 0
    readonly_fields = ['class_name', 'confidence', 'bbox_x', 'bbox_y', 'bbox_width', 'bbox_height']


@admin.register(Detection)
class DetectionAdmin(admin.ModelAdmin):
    list_display = ['id', 'timestamp', 'detections_count', 'confidence_avg', 'processing_time']
    list_filter = ['timestamp']
    readonly_fields = ['timestamp', 'detections_count', 'confidence_avg', 'processing_time']
    inlines = [DetectionResultInline]
    
    def has_add_permission(self, request):
        return False


@admin.register(DetectionResult)
class DetectionResultAdmin(admin.ModelAdmin):
    list_display = ['detection', 'class_name', 'confidence']
    list_filter = ['class_name', 'detection__timestamp']
    readonly_fields = ['detection', 'class_name', 'confidence', 'bbox_x', 'bbox_y', 'bbox_width', 'bbox_height']
    
    def has_add_permission(self, request):
        return False 