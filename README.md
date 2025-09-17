# Traffic Sign Detection Web Application

A real-time traffic sign detection and classification web application built with Django (backend) and React (frontend), powered by YOLOv8 and trained on the GTSRB dataset.

## Features

- **Real-time Detection**: Live camera feed with WebSocket-based real-time traffic sign detection
- **User Authentication**: JWT-based authentication with user profiles and settings
- **High Accuracy**: YOLOv8 model trained on GTSRB dataset with 43 traffic sign classes
- **Modern UI**: Beautiful, responsive React frontend with Tailwind CSS
- **Analytics**: Comprehensive statistics and detection history per user
- **RESTful API**: Django REST Framework backend with full API documentation
- **Cloud Ready**: Docker containerized with deployment configs for major cloud platforms

## Tech Stack

### Backend
- Django 4.2
- Django REST Framework
- Django Channels (WebSocket support)
- YOLOv8 (Ultralytics)
- OpenCV
- Redis (for WebSocket channels)

### Frontend
- React 18
- Tailwind CSS
- Recharts (for analytics)
- Lucide React (icons)
- Axios (HTTP client)

## Prerequisites

- Python 3.8+
- Node.js 16+
- Redis Server
- Webcam/Camera (for real-time detection)

## Installation

### 1. Clone the repository
```bash
git clone <repository-url>
cd yolo
```

### 2. Backend Setup

#### Install Python dependencies
```bash
pip install -r requirements.txt
```

#### Start Redis server
```bash
# On Ubuntu/Debian
sudo systemctl start redis-server

# On macOS with Homebrew
brew services start redis

# Or run directly
redis-server
```

#### Run Django migrations
```bash
cd backend
python manage.py migrate
```

#### Create a superuser (optional)
```bash
python manage.py createsuperuser
```

#### Start the Django development server
```bash
python manage.py runserver
```

The backend will be available at `http://localhost:8000`

### 3. Frontend Setup

#### Install Node.js dependencies
```bash
cd frontend
npm install
```

#### Start the React development server
```bash
npm start
```

The frontend will be available at `http://localhost:3000`

## Usage

### 1. Dashboard
- Overview of system statistics
- Quick access to all features
- Performance metrics

### 2. Real-time Detection
- Click "Start Camera" to begin live detection
- Traffic signs will be automatically detected and highlighted
- Real-time statistics displayed on the side panel

### 3. History
- View all past detection sessions
- Search and filter by sign types
- Sort by various criteria (date, confidence, etc.)

### 4. Statistics
- Comprehensive analytics dashboard
- Charts showing detection patterns
- Performance insights and system status

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `POST /api/auth/token/refresh/` - Refresh JWT token
- `GET /api/auth/profile/` - Get user profile
- `PUT /api/auth/profile/update/` - Update user profile
- `POST /api/auth/change-password/` - Change password
- `DELETE /api/auth/delete-account/` - Delete account

### Detection
- `POST /api/detect/` - Single image detection
- `GET /api/detections/` - Get user's detection history (requires auth)
- `GET /api/stats/` - Get user's detection statistics (requires auth)
- `GET /api/global-stats/` - Get global detection statistics

### WebSocket
- `ws://localhost:8000/ws/detect/` - Real-time detection WebSocket (supports authenticated and anonymous users)

## GTSRB Classes

The model is trained on the German Traffic Sign Recognition Benchmark (GTSRB) dataset with 43 classes:

- Speed limits (20, 30, 50, 60, 70, 80, 100, 120 km/h)
- No passing signs
- Traffic signals
- Stop and yield signs
- Directional signs
- Warning signs (curves, pedestrians, etc.)
- And many more...

## Model Information

- **Architecture**: YOLOv8
- **Dataset**: GTSRB (German Traffic Sign Recognition Benchmark)
- **Classes**: 43 traffic sign types
- **Input Size**: 640x640
- **Confidence Threshold**: 0.25

## Development

### Backend Development
```bash
cd backend
python manage.py runserver --settings=traffic_sign_detector.settings
```

### Frontend Development
```bash
cd frontend
npm start
```

### Building for Production

#### Frontend Build
```bash
cd frontend
npm run build
```

#### Django Production Settings
Update `settings.py` for production:
- Set `DEBUG = False`
- Configure `ALLOWED_HOSTS`
- Use a production database
- Set up proper static file serving

## Troubleshooting

### Common Issues

1. **Camera not working**: Ensure browser permissions are granted for camera access
2. **WebSocket connection failed**: Check if Redis is running and accessible
3. **Model loading error**: Verify the YOLOv8 model file exists in the project root
4. **CORS issues**: Ensure Django CORS settings are properly configured

### Performance Tips

1. **GPU Acceleration**: Install CUDA-compatible PyTorch for faster inference
2. **Model Optimization**: Consider using TensorRT or ONNX for production deployment
3. **Frame Rate**: Adjust detection frequency in real-time mode for better performance

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- YOLOv8 by Ultralytics
- GTSRB Dataset by Institut für Neuroinformatik
- Django and React communities

## Cloud Deployment

### Quick Deploy Options

#### Railway
[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template)

1. Click the deploy button above
2. Connect your GitHub repository
3. Add environment variables:
   - `SECRET_KEY` (auto-generated)
   - `DATABASE_URL` (auto-configured with PostgreSQL)
   - `REDIS_URL` (auto-configured with Redis)
4. Deploy!

#### Heroku
[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

1. Click the deploy button above
2. Set app name and region
3. Configure environment variables (auto-populated from app.json)
4. Deploy and wait for build completion

#### Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose up -d

# Or build and run manually
docker build -t traffic-sign-detector .
docker run -p 8000:8000 -e SECRET_KEY=your-secret-key traffic-sign-detector
```

### Manual Cloud Deployment

#### DigitalOcean App Platform

1. Create a new app from your GitHub repository
2. Configure build settings:
   - Build Command: `npm run build` (for frontend)
   - Run Command: `cd backend && gunicorn traffic_sign_detector.wsgi`
3. Add environment variables
4. Add PostgreSQL and Redis databases
5. Deploy

#### AWS (EC2 + RDS + ElastiCache)

1. Launch EC2 instance with Ubuntu
2. Set up RDS PostgreSQL database
3. Set up ElastiCache Redis cluster
4. Install Docker and Docker Compose
5. Clone repository and configure environment variables
6. Run with Docker Compose

#### Google Cloud Platform

1. Use Google Cloud Run for containerized deployment
2. Set up Cloud SQL for PostgreSQL
3. Set up Memorystore for Redis
4. Configure environment variables
5. Deploy container

### Environment Variables for Production

```env
SECRET_KEY=your-production-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://user:password@host:port/database
REDIS_URL=redis://host:port/0
CORS_ALLOWED_ORIGINS=https://yourdomain.com
```

### Production Checklist

- [ ] Set `DEBUG=False`
- [ ] Use a strong `SECRET_KEY`
- [ ] Configure PostgreSQL database
- [ ] Set up Redis for WebSocket channels
- [ ] Configure CORS for your domain
- [ ] Set up SSL/HTTPS
- [ ] Configure static file serving (WhiteNoise included)
- [ ] Set up monitoring and logging
- [ ] Configure email settings for notifications
- [ ] Set up regular database backups

## Support

For issues and questions, please open an issue on the GitHub repository. 