import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, Clock, Target, Award } from 'lucide-react';
import axios from 'axios';

const Statistics = () => {
  const [stats, setStats] = useState({
    total_detections: 0,
    avg_processing_time: 0,
    avg_confidence: 0,
    most_detected_signs: []
  });
  const [detections, setDetections] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [statsResponse, detectionsResponse] = await Promise.all([
        axios.get('/api/stats/'),
        axios.get('/api/detections/')
      ]);
      
      setStats(statsResponse.data);
      setDetections(detectionsResponse.data);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Process data for charts
  const processChartData = () => {
    if (!detections.length) return { timeData: [], confidenceData: [] };

    // Group detections by hour for time-based chart
    const hourlyData = {};
    detections.forEach(detection => {
      const hour = new Date(detection.timestamp).getHours();
      if (!hourlyData[hour]) {
        hourlyData[hour] = { hour: `${hour}:00`, count: 0, avgConfidence: 0, totalConfidence: 0 };
      }
      hourlyData[hour].count += detection.detections_count;
      hourlyData[hour].totalConfidence += detection.confidence_avg;
    });

    const timeData = Object.values(hourlyData).map(item => ({
      ...item,
      avgConfidence: (item.totalConfidence / item.count * 100).toFixed(1)
    })).sort((a, b) => parseInt(a.hour) - parseInt(b.hour));

    // Confidence distribution
    const confidenceRanges = {
      'High (80-100%)': 0,
      'Medium (60-79%)': 0,
      'Low (0-59%)': 0
    };

    detections.forEach(detection => {
      detection.results?.forEach(result => {
        const confidence = result.confidence * 100;
        if (confidence >= 80) confidenceRanges['High (80-100%)']++;
        else if (confidence >= 60) confidenceRanges['Medium (60-79%)']++;
        else confidenceRanges['Low (0-59%)']++;
      });
    });

    const confidenceData = Object.entries(confidenceRanges).map(([name, value]) => ({
      name,
      value,
      percentage: ((value / Object.values(confidenceRanges).reduce((a, b) => a + b, 1)) * 100).toFixed(1)
    }));

    return { timeData, confidenceData };
  };

  const { timeData, confidenceData } = processChartData();

  // Colors for charts
  const COLORS = ['#22c55e', '#f59e0b', '#ef4444'];

  const StatCard = ({ title, value, icon: Icon, color, suffix = '', description }) => (
    <div className="card">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-full ${color.replace('text', 'bg').replace('600', '100')}`}>
          <Icon className={`w-6 h-6 ${color}`} />
        </div>
        <div className="text-right">
          <p className={`text-3xl font-bold ${color}`}>
            {loading ? '...' : `${value}${suffix}`}
          </p>
          <p className="text-sm font-medium text-gray-900">{title}</p>
        </div>
      </div>
      <p className="text-sm text-gray-600">{description}</p>
    </div>
  );

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
          <p className="text-gray-600 mt-4">Loading statistics...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Detection Statistics</h1>
        <p className="text-gray-600">Analytics and insights from your traffic sign detections</p>
      </div>

      {/* Overview Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Detections"
          value={stats.total_detections}
          icon={Target}
          color="text-primary-600"
          description="Total number of detection sessions"
        />
        <StatCard
          title="Avg Processing Time"
          value={stats.avg_processing_time}
          icon={Clock}
          color="text-success-600"
          suffix="s"
          description="Average time per detection"
        />
        <StatCard
          title="Avg Confidence"
          value={Math.round(stats.avg_confidence * 100)}
          icon={TrendingUp}
          color="text-warning-600"
          suffix="%"
          description="Average confidence score"
        />
        <StatCard
          title="Sign Types"
          value={stats.most_detected_signs?.length || 0}
          icon={Award}
          color="text-danger-600"
          description="Different sign types detected"
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Detection Activity by Hour */}
        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Detection Activity by Hour</h2>
          {timeData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={timeData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="hour" />
                <YAxis />
                <Tooltip 
                  formatter={(value, name) => [
                    name === 'count' ? `${value} detections` : `${value}% confidence`,
                    name === 'count' ? 'Detections' : 'Avg Confidence'
                  ]}
                />
                <Bar dataKey="count" fill="#3b82f6" name="count" />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-64 text-gray-500">
              <p>No data available</p>
            </div>
          )}
        </div>

        {/* Confidence Distribution */}
        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Confidence Distribution</h2>
          {confidenceData.some(d => d.value > 0) ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={confidenceData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percentage }) => `${name}: ${percentage}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {confidenceData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => [`${value} detections`, 'Count']} />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-64 text-gray-500">
              <p>No data available</p>
            </div>
          )}
        </div>
      </div>

      {/* Most Detected Signs */}
      {stats.most_detected_signs && stats.most_detected_signs.length > 0 && (
        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Most Detected Signs</h2>
          <div className="space-y-4">
            {stats.most_detected_signs.map((sign, index) => {
              const percentage = (sign.count / stats.most_detected_signs[0].count) * 100;
              return (
                <div key={index} className="flex items-center space-x-4">
                  <div className="flex items-center justify-center w-8 h-8 bg-primary-600 text-white rounded-full text-sm font-bold">
                    {index + 1}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-medium text-gray-900">{sign.class_name}</span>
                      <span className="text-sm text-gray-600">{sign.count} detections</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-primary-600 h-2 rounded-full transition-all duration-500"
                        style={{ width: `${percentage}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Performance Insights */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Performance Insights</h2>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-success-50 rounded-lg">
              <span className="text-success-800 font-medium">Model Accuracy</span>
              <span className="text-success-600 font-bold">
                {Math.round(stats.avg_confidence * 100)}%
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-primary-50 rounded-lg">
              <span className="text-primary-800 font-medium">Processing Speed</span>
              <span className="text-primary-600 font-bold">
                {stats.avg_processing_time.toFixed(2)}s
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-warning-50 rounded-lg">
              <span className="text-warning-800 font-medium">Detection Rate</span>
              <span className="text-warning-600 font-bold">
                {detections.length > 0 ? 
                  (detections.reduce((sum, d) => sum + d.detections_count, 0) / detections.length).toFixed(1)
                  : '0'
                } per session
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">System Status</h2>
          <div className="space-y-4">
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-success-500 rounded-full"></div>
              <span className="text-gray-700">YOLOv8 Model: Active</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-success-500 rounded-full"></div>
              <span className="text-gray-700">GTSRB Dataset: 43 Classes</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-success-500 rounded-full"></div>
              <span className="text-gray-700">WebSocket: Connected</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-success-500 rounded-full"></div>
              <span className="text-gray-700">Database: Operational</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Statistics; 