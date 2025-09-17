import cv2
import numpy as np
from ultralytics import YOLO
from django.conf import settings
import base64
import io
from PIL import Image
import time


class YOLODetector:
    def __init__(self):
        self.model = YOLO(settings.MODEL_PATH)
        self.class_names = self.get_gtsrb_class_names()
    
    def get_gtsrb_class_names(self):
        """
        GTSRB dataset class names (German Traffic Sign Recognition Benchmark)
        """
        return {
            0: 'Speed limit (20km/h)',
            1: 'Speed limit (30km/h)', 
            2: 'Speed limit (50km/h)',
            3: 'Speed limit (60km/h)',
            4: 'Speed limit (70km/h)',
            5: 'Speed limit (80km/h)',
            6: 'End of speed limit (80km/h)',
            7: 'Speed limit (100km/h)',
            8: 'Speed limit (120km/h)',
            9: 'No passing',
            10: 'No passing veh over 3.5 tons',
            11: 'Right-of-way at intersection',
            12: 'Priority road',
            13: 'Yield',
            14: 'Stop',
            15: 'No vehicles',
            16: 'Veh > 3.5 tons prohibited',
            17: 'No entry',
            18: 'General caution',
            19: 'Dangerous curve left',
            20: 'Dangerous curve right',
            21: 'Double curve',
            22: 'Bumpy road',
            23: 'Slippery road',
            24: 'Road narrows on the right',
            25: 'Road work',
            26: 'Traffic signals',
            27: 'Pedestrians',
            28: 'Children crossing',
            29: 'Bicycles crossing',
            30: 'Beware of ice/snow',
            31: 'Wild animals crossing',
            32: 'End speed + passing limits',
            33: 'Turn right ahead',
            34: 'Turn left ahead',
            35: 'Ahead only',
            36: 'Go straight or right',
            37: 'Go straight or left',
            38: 'Keep right',
            39: 'Keep left',
            40: 'Roundabout mandatory',
            41: 'End of no passing',
            42: 'End no passing veh > 3.5 tons'
        }
    
    def detect_from_base64(self, base64_image):
        """
        Detect traffic signs from base64 encoded image
        """
        try:
            start_time = time.time()
            
            # Decode base64 image
            image_data = base64.b64decode(base64_image.split(',')[1])
            image = Image.open(io.BytesIO(image_data))
            image_np = np.array(image)
            
            # Convert RGB to BGR for OpenCV
            if len(image_np.shape) == 3:
                image_np = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
            
            # Run inference
            results = self.model(image_np, conf=0.25)
            
            detections = []
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        # Get bounding box coordinates (normalized)
                        x1, y1, x2, y2 = box.xyxyn[0].tolist()
                        confidence = box.conf[0].item()
                        class_id = int(box.cls[0].item())
                        
                        # Get class name
                        class_name = self.class_names.get(class_id, f"Unknown ({class_id})")
                        
                        detections.append({
                            'class_name': class_name,
                            'confidence': confidence,
                            'bbox_x': x1,
                            'bbox_y': y1,
                            'bbox_width': x2 - x1,
                            'bbox_height': y2 - y1
                        })
            
            processing_time = time.time() - start_time
            
            return {
                'detections': detections,
                'processing_time': processing_time,
                'detections_count': len(detections),
                'confidence_avg': np.mean([d['confidence'] for d in detections]) if detections else 0.0
            }
            
        except Exception as e:
            print(f"Detection error: {str(e)}")
            return {
                'detections': [],
                'processing_time': 0.0,
                'detections_count': 0,
                'confidence_avg': 0.0,
                'error': str(e)
            }
    
    def detect_from_cv2_frame(self, frame):
        """
        Detect traffic signs from OpenCV frame
        """
        try:
            start_time = time.time()
            
            # Run inference
            results = self.model(frame, conf=0.25)
            
            detections = []
            annotated_frame = frame.copy()
            
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        # Get bounding box coordinates
                        x1, y1, x2, y2 = box.xyxy[0].tolist()
                        confidence = box.conf[0].item()
                        class_id = int(box.cls[0].item())
                        
                        # Get class name
                        class_name = self.class_names.get(class_id, f"Unknown ({class_id})")
                        
                        # Draw bounding box and label
                        cv2.rectangle(annotated_frame, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
                        label = f"{class_name}: {confidence:.2f}"
                        cv2.putText(annotated_frame, label, (int(x1), int(y1-10)), 
                                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
                        
                        # Normalize coordinates for storage
                        h, w = frame.shape[:2]
                        detections.append({
                            'class_name': class_name,
                            'confidence': confidence,
                            'bbox_x': x1 / w,
                            'bbox_y': y1 / h,
                            'bbox_width': (x2 - x1) / w,
                            'bbox_height': (y2 - y1) / h
                        })
            
            processing_time = time.time() - start_time
            
            return {
                'detections': detections,
                'annotated_frame': annotated_frame,
                'processing_time': processing_time,
                'detections_count': len(detections),
                'confidence_avg': np.mean([d['confidence'] for d in detections]) if detections else 0.0
            }
            
        except Exception as e:
            print(f"Detection error: {str(e)}")
            return {
                'detections': [],
                'annotated_frame': frame,
                'processing_time': 0.0,
                'detections_count': 0,
                'confidence_avg': 0.0,
                'error': str(e)
            } 