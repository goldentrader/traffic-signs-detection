import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Camera, Square, Play, Pause, AlertCircle, Wifi, WifiOff } from 'lucide-react';

const RealtimeDetection = () => {
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const wsRef = useRef(null);
  const streamRef = useRef(null);
  
  const [isStreaming, setIsStreaming] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [detections, setDetections] = useState([]);
  const [stats, setStats] = useState({
    detections_count: 0,
    processing_time: 0,
    confidence_avg: 0
  });
  const [error, setError] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);

  // Initialize WebSocket connection
  const connectWebSocket = useCallback(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/detect/`;
    
    wsRef.current = new WebSocket(wsUrl);
    
    wsRef.current.onopen = () => {
      console.log('WebSocket connected');
      setIsConnected(true);
      setError(null);
    };
    
    wsRef.current.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      if (data.type === 'detection_result') {
        setDetections(data.detections);
        setStats({
          detections_count: data.detections_count,
          processing_time: data.processing_time,
          confidence_avg: data.confidence_avg
        });
        setIsProcessing(false);
        drawDetections(data.detections);
      } else if (data.type === 'error') {
        setError(data.message);
        setIsProcessing(false);
      }
    };
    
    wsRef.current.onclose = () => {
      console.log('WebSocket disconnected');
      setIsConnected(false);
    };
    
    wsRef.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setError('WebSocket connection failed');
      setIsConnected(false);
    };
  }, []);

  // Start camera stream
  const startCamera = async () => {
    try {
      setError(null);
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 640, height: 480 }
      });
      
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        streamRef.current = stream;
      }
      
      if (!isConnected) {
        connectWebSocket();
      }
      
      setIsStreaming(true);
    } catch (err) {
      setError('Failed to access camera. Please ensure camera permissions are granted.');
      console.error('Camera error:', err);
    }
  };

  // Stop camera stream
  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    
    if (wsRef.current) {
      wsRef.current.close();
    }
    
    setIsStreaming(false);
    setDetections([]);
    clearCanvas();
  };

  // Capture frame and send for detection
  const captureAndDetect = useCallback(() => {
    if (!videoRef.current || !canvasRef.current || !isConnected || isProcessing) {
      return;
    }

    const video = videoRef.current;
    const canvas = canvasRef.current;
    const context = canvas.getContext('2d');
    
    // Set canvas size to match video
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    
    // Draw video frame to canvas
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    
    // Convert to base64
    const base64Image = canvas.toDataURL('image/jpeg', 0.8);
    
    // Send to WebSocket
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      setIsProcessing(true);
      wsRef.current.send(JSON.stringify({
        type: 'detect_frame',
        image: base64Image
      }));
    }
  }, [isConnected, isProcessing]);

  // Draw detection boxes on canvas
  const drawDetections = (detectionResults) => {
    if (!canvasRef.current || !videoRef.current) return;
    
    const canvas = canvasRef.current;
    const context = canvas.getContext('2d');
    const video = videoRef.current;
    
    // Clear previous drawings
    context.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw detection boxes
    detectionResults.forEach((detection) => {
      const x = detection.bbox_x * canvas.width;
      const y = detection.bbox_y * canvas.height;
      const width = detection.bbox_width * canvas.width;
      const height = detection.bbox_height * canvas.height;
      
      // Draw bounding box
      context.strokeStyle = '#22c55e';
      context.lineWidth = 2;
      context.strokeRect(x, y, width, height);
      
      // Draw label background
      const label = `${detection.class_name}: ${(detection.confidence * 100).toFixed(1)}%`;
      context.font = '14px Arial';
      const textWidth = context.measureText(label).width;
      
      context.fillStyle = '#22c55e';
      context.fillRect(x, y - 25, textWidth + 10, 20);
      
      // Draw label text
      context.fillStyle = 'white';
      context.fillText(label, x + 5, y - 10);
    });
  };

  // Clear canvas
  const clearCanvas = () => {
    if (canvasRef.current) {
      const context = canvasRef.current.getContext('2d');
      context.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
    }
  };

  // Auto-capture frames when streaming
  useEffect(() => {
    let interval;
    if (isStreaming && isConnected) {
      interval = setInterval(captureAndDetect, 1000); // Capture every second
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isStreaming, isConnected, captureAndDetect]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Real-time Detection</h1>
        <p className="text-gray-600">Live traffic sign detection using your camera</p>
      </div>

      {/* Connection Status */}
      <div className="flex justify-center">
        <div className={`flex items-center space-x-2 px-4 py-2 rounded-full ${
          isConnected ? 'bg-success-100 text-success-700' : 'bg-danger-100 text-danger-700'
        }`}>
          {isConnected ? <Wifi className="w-4 h-4" /> : <WifiOff className="w-4 h-4" />}
          <span className="text-sm font-medium">
            {isConnected ? 'Connected' : 'Disconnected'}
          </span>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-danger-50 border border-danger-200 rounded-lg p-4">
          <div className="flex items-center space-x-2">
            <AlertCircle className="w-5 h-5 text-danger-600" />
            <span className="text-danger-800">{error}</span>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Video Feed */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Camera Feed</h2>
              <div className="flex space-x-2">
                {!isStreaming ? (
                  <button
                    onClick={startCamera}
                    className="btn-primary flex items-center space-x-2"
                  >
                    <Play className="w-4 h-4" />
                    <span>Start Camera</span>
                  </button>
                ) : (
                  <button
                    onClick={stopCamera}
                    className="btn-danger flex items-center space-x-2"
                  >
                    <Square className="w-4 h-4" />
                    <span>Stop Camera</span>
                  </button>
                )}
              </div>
            </div>
            
            <div className="relative bg-gray-900 rounded-lg overflow-hidden">
              <div className="video-container">
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-full object-cover"
                />
                <canvas
                  ref={canvasRef}
                  className="absolute top-0 left-0 w-full h-full pointer-events-none"
                />
                {!isStreaming && (
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="text-center text-white">
                      <Camera className="w-16 h-16 mx-auto mb-4 opacity-50" />
                      <p className="text-lg">Camera not active</p>
                      <p className="text-sm opacity-75">Click "Start Camera" to begin detection</p>
                    </div>
                  </div>
                )}
                {isProcessing && (
                  <div className="absolute top-4 right-4 bg-primary-600 text-white px-3 py-1 rounded-full text-sm">
                    Processing...
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Detection Results */}
        <div className="space-y-6">
          {/* Stats */}
          <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Detection Stats</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Detections:</span>
                <span className="font-semibold text-primary-600">{stats.detections_count}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Processing Time:</span>
                <span className="font-semibold text-success-600">
                  {stats.processing_time.toFixed(3)}s
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Avg Confidence:</span>
                <span className="font-semibold text-warning-600">
                  {(stats.confidence_avg * 100).toFixed(1)}%
                </span>
              </div>
            </div>
          </div>

          {/* Current Detections */}
          <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Current Detections</h3>
            {detections.length > 0 ? (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {detections.map((detection, index) => (
                  <div key={index} className="bg-gray-50 rounded-lg p-3">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <p className="font-medium text-gray-900 text-sm">
                          {detection.class_name}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          Confidence: {(detection.confidence * 100).toFixed(1)}%
                        </p>
                      </div>
                      <div className={`px-2 py-1 rounded text-xs font-medium ${
                        detection.confidence > 0.8 
                          ? 'bg-success-100 text-success-800'
                          : detection.confidence > 0.6
                          ? 'bg-warning-100 text-warning-800'
                          : 'bg-danger-100 text-danger-800'
                      }`}>
                        {(detection.confidence * 100).toFixed(0)}%
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <Camera className="w-8 h-8 mx-auto mb-2 opacity-50" />
                <p>No detections yet</p>
                <p className="text-sm">Start the camera to begin detection</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RealtimeDetection; 