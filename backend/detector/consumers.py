import json
import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from .yolo_detector import YOLODetector
from .models import Detection, DetectionResult


class DetectionConsumer(AsyncWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.detector = YOLODetector()
    
    async def connect(self):
        await self.accept()
        
        # Check if user is authenticated
        user = self.scope.get("user", AnonymousUser())
        is_authenticated = user.is_authenticated
        
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': 'Connected to detection service',
            'authenticated': is_authenticated,
            'username': user.username if is_authenticated else None
        }))
    
    async def disconnect(self, close_code):
        pass
    
    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'detect_frame':
                base64_image = data.get('image')
                if base64_image:
                    # Run detection in a thread to avoid blocking
                    result = await asyncio.get_event_loop().run_in_executor(
                        None, self.detector.detect_from_base64, base64_image
                    )
                    
                    # Save to database if there are detections and user is authenticated
                    user = self.scope.get("user", AnonymousUser())
                    if result['detections_count'] > 0 and user.is_authenticated:
                        await self.save_detection(result, user)
                    
                    # Send results back to client
                    await self.send(text_data=json.dumps({
                        'type': 'detection_result',
                        'detections': result['detections'],
                        'processing_time': result['processing_time'],
                        'detections_count': result['detections_count'],
                        'confidence_avg': result['confidence_avg'],
                        'saved': result['detections_count'] > 0 and user.is_authenticated
                    }))
                    
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': str(e)
            }))
    
    @database_sync_to_async
    def save_detection(self, result, user):
        """Save detection results to database"""
        try:
            detection = Detection.objects.create(
                user=user,
                detections_count=result['detections_count'],
                confidence_avg=result['confidence_avg'],
                processing_time=result['processing_time']
            )
            
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
                
        except Exception as e:
            print(f"Error saving detection: {str(e)}") 