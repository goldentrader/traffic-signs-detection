#!/bin/bash

# Traffic Sign Detector - Server Startup Script
echo "🚀 Starting Traffic Sign Detection System..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists python3; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

if ! command_exists node; then
    echo "❌ Node.js is not installed"
    exit 1
fi

if ! command_exists redis-server; then
    echo "❌ Redis is not installed"
    exit 1
fi

echo "✅ All prerequisites found"

# Start Redis server
echo "🔴 Starting Redis server..."
redis-server --daemonize yes

# Check if Redis is running
if ! redis-cli ping >/dev/null 2>&1; then
    echo "❌ Failed to start Redis server"
    exit 1
fi
echo "✅ Redis server started"

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip install -r requirements.txt

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
cd frontend
npm install
cd ..

# Run Django migrations
echo "🗄️ Running Django migrations..."
cd backend
python manage.py migrate
cd ..

# Create a function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    redis-cli shutdown 2>/dev/null
    echo "✅ Cleanup completed"
    exit
}

# Set trap to cleanup on script exit
trap cleanup INT TERM

# Start Django backend
echo "🌐 Starting Django backend server..."
cd backend
python manage.py runserver &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 3

# Start React frontend
echo "⚛️ Starting React frontend server..."
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

echo ""
echo "🎉 Traffic Sign Detection System is now running!"
echo ""
echo "📍 Backend (Django):  http://localhost:8000"
echo "📍 Frontend (React):  http://localhost:3000"
echo "📍 Admin Panel:       http://localhost:8000/admin"
echo ""
echo "🎥 Open http://localhost:3000 in your browser to start detecting traffic signs!"
echo ""
echo "Press Ctrl+C to stop all servers"

# Wait for background processes
wait 