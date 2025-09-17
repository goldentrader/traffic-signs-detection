import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Camera, Upload, BarChart3, History, Activity, Clock, Target, TrendingUp } from 'lucide-react';
import axios from 'axios';

const Dashboard = () => {
  const [stats, setStats] = useState({
    total_detections: 0,
    avg_processing_time: 0,
    avg_confidence: 0,
    most_detected_signs: []
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await axios.get('/api/global-stats/');
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const StatCard = ({ title, value, icon: Icon, color, suffix = '' }) => (
    <div className="card">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className={`text-2xl font-bold ${color}`}>
            {loading ? '...' : `${value}${suffix}`}
          </p>
        </div>
        <div className={`p-3 rounded-full ${color.replace('text', 'bg').replace('600', '100')}`}>
          <Icon className={`w-6 h-6 ${color}`} />
        </div>
      </div>
    </div>
  );

  const QuickActionCard = ({ title, description, icon: Icon, to, color, bgColor }) => (
    <Link to={to} className="group">
      <div className={`card hover:shadow-md transition-all duration-200 border-l-4 ${color}`}>
        <div className="flex items-center space-x-4">
          <div className={`p-3 rounded-full ${bgColor} group-hover:scale-110 transition-transform duration-200`}>
            <Icon className={`w-6 h-6 ${color.replace('border', 'text')}`} />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
            <p className="text-gray-600">{description}</p>
          </div>
        </div>
      </div>
    </Link>
  );

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Traffic Sign Detection System
        </h1>
        <p className="text-xl text-gray-600 max-w-2xl mx-auto">
          Real-time detection and classification of traffic signs using YOLOv8 and GTSRB dataset
        </p>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Detections"
          value={stats.total_detections}
          icon={Target}
          color="text-primary-600"
        />
        <StatCard
          title="Avg Processing Time"
          value={stats.avg_processing_time}
          icon={Clock}
          color="text-success-600"
          suffix="s"
        />
        <StatCard
          title="Avg Confidence"
          value={Math.round(stats.avg_confidence * 100)}
          icon={TrendingUp}
          color="text-warning-600"
          suffix="%"
        />
        <StatCard
          title="Active Sessions"
          value="1"
          icon={Activity}
          color="text-danger-600"
        />
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <QuickActionCard
            title="Real-time Detection"
            description="Start live camera detection"
            icon={Camera}
            to="/realtime"
            color="border-primary-500"
            bgColor="bg-primary-100"
          />
          <QuickActionCard
            title="View History"
            description="Browse detection history"
            icon={History}
            to="/history"
            color="border-success-500"
            bgColor="bg-success-100"
          />
          <QuickActionCard
            title="Statistics"
            description="View detailed analytics"
            icon={BarChart3}
            to="/statistics"
            color="border-warning-500"
            bgColor="bg-warning-100"
          />
        </div>
      </div>

      {/* Most Detected Signs */}
      {stats.most_detected_signs && stats.most_detected_signs.length > 0 && (
        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Most Detected Signs</h2>
          <div className="card">
            <div className="space-y-4">
              {stats.most_detected_signs.map((sign, index) => (
                <div key={index} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                      {index + 1}
                    </div>
                    <span className="font-medium text-gray-900">{sign.class_name}</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-sm text-gray-600">Detected</span>
                    <span className="font-bold text-primary-600">{sign.count}</span>
                    <span className="text-sm text-gray-600">times</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Features */}
      <div className="bg-gradient-to-r from-primary-600 to-primary-700 rounded-xl text-white p-8">
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-4">Powered by YOLOv8</h2>
          <p className="text-xl opacity-90 mb-6">
            State-of-the-art object detection for real-time traffic sign recognition
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
            <div className="text-center">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-3">
                <Target className="w-6 h-6" />
              </div>
              <h3 className="font-semibold mb-2">High Accuracy</h3>
              <p className="opacity-80">Trained on GTSRB dataset with 43 traffic sign classes</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-3">
                <Clock className="w-6 h-6" />
              </div>
              <h3 className="font-semibold mb-2">Real-time Processing</h3>
              <p className="opacity-80">Fast inference with optimized YOLOv8 model</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-3">
                <Camera className="w-6 h-6" />
              </div>
              <h3 className="font-semibold mb-2">Live Detection</h3>
              <p className="opacity-80">WebSocket-based real-time video processing</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 