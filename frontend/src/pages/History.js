import React, { useState, useEffect } from 'react';
import { Calendar, Clock, Target, TrendingUp, Search, Filter } from 'lucide-react';
import axios from 'axios';

const History = () => {
  const [detections, setDetections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('timestamp');

  useEffect(() => {
    fetchDetections();
  }, []);

  const fetchDetections = async () => {
    try {
      const response = await axios.get('/api/detections/');
      setDetections(response.data);
    } catch (error) {
      console.error('Error fetching detections:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredDetections = detections
    .filter(detection => {
      if (!searchTerm) return true;
      return detection.results.some(result => 
        result.class_name.toLowerCase().includes(searchTerm.toLowerCase())
      );
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'timestamp':
          return new Date(b.timestamp) - new Date(a.timestamp);
        case 'detections_count':
          return b.detections_count - a.detections_count;
        case 'confidence_avg':
          return b.confidence_avg - a.confidence_avg;
        case 'processing_time':
          return a.processing_time - b.processing_time;
        default:
          return 0;
      }
    });

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  const DetectionCard = ({ detection }) => (
    <div className="card hover:shadow-md transition-shadow duration-200">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
            <Target className="w-5 h-5 text-primary-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">
              Detection #{detection.id}
            </h3>
            <p className="text-sm text-gray-500">
              {formatDate(detection.timestamp)}
            </p>
          </div>
        </div>
        <div className="text-right">
          <div className="flex items-center space-x-1 text-sm text-gray-600 mb-1">
            <Clock className="w-4 h-4" />
            <span>{detection.processing_time.toFixed(3)}s</span>
          </div>
          <div className="flex items-center space-x-1 text-sm text-gray-600">
            <TrendingUp className="w-4 h-4" />
            <span>{(detection.confidence_avg * 100).toFixed(1)}%</span>
          </div>
        </div>
      </div>

      {/* Detection Stats */}
      <div className="grid grid-cols-3 gap-4 mb-4 p-4 bg-gray-50 rounded-lg">
        <div className="text-center">
          <p className="text-2xl font-bold text-primary-600">{detection.detections_count}</p>
          <p className="text-xs text-gray-600">Signs Detected</p>
        </div>
        <div className="text-center">
          <p className="text-2xl font-bold text-success-600">
            {(detection.confidence_avg * 100).toFixed(0)}%
          </p>
          <p className="text-xs text-gray-600">Avg Confidence</p>
        </div>
        <div className="text-center">
          <p className="text-2xl font-bold text-warning-600">
            {detection.processing_time.toFixed(2)}s
          </p>
          <p className="text-xs text-gray-600">Process Time</p>
        </div>
      </div>

      {/* Detection Results */}
      {detection.results && detection.results.length > 0 && (
        <div>
          <h4 className="font-medium text-gray-900 mb-3">Detected Signs:</h4>
          <div className="space-y-2">
            {detection.results.map((result, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-white border rounded">
                <span className="font-medium text-gray-900 text-sm">
                  {result.class_name}
                </span>
                <div className="flex items-center space-x-2">
                  <div className={`px-2 py-1 rounded text-xs font-medium ${
                    result.confidence > 0.8 
                      ? 'bg-success-100 text-success-800'
                      : result.confidence > 0.6
                      ? 'bg-warning-100 text-warning-800'
                      : 'bg-danger-100 text-danger-800'
                  }`}>
                    {(result.confidence * 100).toFixed(1)}%
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Detection History</h1>
        <p className="text-gray-600">Browse your past traffic sign detections</p>
      </div>

      {/* Filters */}
      <div className="card">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search by sign name..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              />
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            <Filter className="w-4 h-4 text-gray-400" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            >
              <option value="timestamp">Sort by Date</option>
              <option value="detections_count">Sort by Detection Count</option>
              <option value="confidence_avg">Sort by Confidence</option>
              <option value="processing_time">Sort by Processing Time</option>
            </select>
          </div>
        </div>
      </div>

      {/* Results Summary */}
      <div className="bg-primary-50 border border-primary-200 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Calendar className="w-5 h-5 text-primary-600" />
            <span className="font-medium text-primary-900">
              Showing {filteredDetections.length} of {detections.length} detections
            </span>
          </div>
          {searchTerm && (
            <button
              onClick={() => setSearchTerm('')}
              className="text-primary-600 hover:text-primary-800 text-sm font-medium"
            >
              Clear search
            </button>
          )}
        </div>
      </div>

      {/* Detection List */}
      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto"></div>
          <p className="text-gray-600 mt-4">Loading detections...</p>
        </div>
      ) : filteredDetections.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {filteredDetections.map((detection) => (
            <DetectionCard key={detection.id} detection={detection} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12">
          <Target className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {searchTerm ? 'No matching detections' : 'No detections yet'}
          </h3>
          <p className="text-gray-600 mb-4">
            {searchTerm 
              ? 'Try adjusting your search terms'
              : 'Start detecting traffic signs to see them here'
            }
          </p>
          {!searchTerm && (
            <button 
              onClick={() => window.location.href = '/realtime'}
              className="btn-primary"
            >
              Start Detection
            </button>
          )}
        </div>
      )}
    </div>
  );
};

export default History; 