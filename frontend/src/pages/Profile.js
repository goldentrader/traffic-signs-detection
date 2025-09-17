import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Mail, Calendar, MapPin, Settings, Save, Eye, EyeOff, Trash2 } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

const Profile = () => {
  const { user, isAuthenticated, updateProfile, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('profile');
  const [loading, setLoading] = useState(false);
  const [userStats, setUserStats] = useState(null);
  const [profileData, setProfileData] = useState({
    username: '',
    email: '',
    first_name: '',
    last_name: '',
    bio: '',
    location: '',
    preferred_confidence_threshold: 0.25,
    email_notifications: true
  });
  const [passwordData, setPasswordData] = useState({
    old_password: '',
    new_password: '',
    new_password_confirm: ''
  });
  const [showPasswords, setShowPasswords] = useState({
    old: false,
    new: false,
    confirm: false
  });
  const [errors, setErrors] = useState({});
  const [success, setSuccess] = useState('');

  // Redirect if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
  }, [isAuthenticated, navigate]);

  // Load user data and stats
  useEffect(() => {
    if (user) {
      setProfileData({
        username: user.username || '',
        email: user.email || '',
        first_name: user.first_name || '',
        last_name: user.last_name || '',
        bio: user.profile?.bio || '',
        location: user.profile?.location || '',
        preferred_confidence_threshold: user.profile?.preferred_confidence_threshold || 0.25,
        email_notifications: user.profile?.email_notifications ?? true
      });
      
      fetchUserStats();
    }
  }, [user]);

  const fetchUserStats = async () => {
    try {
      const response = await axios.get('/api/auth/profile/stats/');
      setUserStats(response.data);
    } catch (error) {
      console.error('Error fetching user stats:', error);
    }
  };

  const handleProfileChange = (e) => {
    const { name, value, type, checked } = e.target;
    setProfileData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handlePasswordChange = (e) => {
    const { name, value } = e.target;
    setPasswordData(prev => ({
      ...prev,
      [name]: value
    }));
    setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handleProfileSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setErrors({});
    setSuccess('');

    const result = await updateProfile(profileData);
    
    if (result.success) {
      setSuccess('Profile updated successfully!');
    } else {
      setErrors(result.errors);
    }
    
    setLoading(false);
  };

  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setErrors({});
    setSuccess('');

    if (passwordData.new_password !== passwordData.new_password_confirm) {
      setErrors({ new_password_confirm: 'Passwords do not match' });
      setLoading(false);
      return;
    }

    try {
      await axios.post('/api/auth/change-password/', passwordData);
      setSuccess('Password changed successfully!');
      setPasswordData({ old_password: '', new_password: '', new_password_confirm: '' });
    } catch (error) {
      setErrors(error.response?.data || { general: 'Failed to change password' });
    }
    
    setLoading(false);
  };

  const handleDeleteAccount = async () => {
    if (window.confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      try {
        await axios.delete('/api/auth/delete-account/');
        await logout();
        navigate('/');
      } catch (error) {
        setErrors({ general: 'Failed to delete account' });
      }
    }
  };

  if (!isAuthenticated || !user) {
    return null;
  }

  const tabs = [
    { id: 'profile', name: 'Profile', icon: User },
    { id: 'security', name: 'Security', icon: Settings },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Profile Settings</h1>
        <p className="text-gray-600">Manage your account settings and preferences</p>
      </div>

      {/* User Stats Card */}
      {userStats && (
        <div className="card">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Your Statistics</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="text-center">
              <p className="text-2xl font-bold text-primary-600">{userStats.total_sessions}</p>
              <p className="text-sm text-gray-600">Detection Sessions</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-success-600">{userStats.total_signs_detected}</p>
              <p className="text-sm text-gray-600">Signs Detected</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-warning-600">{Math.round(userStats.avg_confidence * 100)}%</p>
              <p className="text-sm text-gray-600">Avg Confidence</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-danger-600">{userStats.avg_processing_time}s</p>
              <p className="text-sm text-gray-600">Avg Processing Time</p>
            </div>
          </div>
        </div>
      )}

      {/* Success/Error Messages */}
      {success && (
        <div className="bg-success-50 border border-success-200 rounded-lg p-4">
          <p className="text-success-800">{success}</p>
        </div>
      )}

      {errors.general && (
        <div className="bg-danger-50 border border-danger-200 rounded-lg p-4">
          <p className="text-danger-800">{errors.general}</p>
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex space-x-8">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-primary-500 text-primary-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.name}</span>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'profile' && (
        <form onSubmit={handleProfileSubmit} className="card space-y-6">
          <h2 className="text-lg font-semibold text-gray-900">Profile Information</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">Username</label>
              <input
                type="text"
                name="username"
                value={profileData.username}
                onChange={handleProfileChange}
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
              {errors.username && <p className="mt-1 text-sm text-danger-600">{errors.username}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Email</label>
              <input
                type="email"
                name="email"
                value={profileData.email}
                onChange={handleProfileChange}
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
              {errors.email && <p className="mt-1 text-sm text-danger-600">{errors.email}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">First Name</label>
              <input
                type="text"
                name="first_name"
                value={profileData.first_name}
                onChange={handleProfileChange}
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Last Name</label>
              <input
                type="text"
                name="last_name"
                value={profileData.last_name}
                onChange={handleProfileChange}
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Location</label>
              <input
                type="text"
                name="location"
                value={profileData.location}
                onChange={handleProfileChange}
                placeholder="City, Country"
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Confidence Threshold</label>
              <input
                type="number"
                name="preferred_confidence_threshold"
                value={profileData.preferred_confidence_threshold}
                onChange={handleProfileChange}
                min="0.1"
                max="1.0"
                step="0.05"
                className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
              />
              <p className="mt-1 text-xs text-gray-500">Minimum confidence for detections (0.1 - 1.0)</p>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Bio</label>
            <textarea
              name="bio"
              value={profileData.bio}
              onChange={handleProfileChange}
              rows={3}
              placeholder="Tell us about yourself..."
              className="mt-1 block w-full rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
            />
          </div>

          <div className="flex items-center">
            <input
              type="checkbox"
              name="email_notifications"
              checked={profileData.email_notifications}
              onChange={handleProfileChange}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
            />
            <label className="ml-2 block text-sm text-gray-900">
              Receive email notifications about detections
            </label>
          </div>

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={loading}
              className="btn-primary flex items-center space-x-2"
            >
              <Save className="w-4 h-4" />
              <span>{loading ? 'Saving...' : 'Save Changes'}</span>
            </button>
          </div>
        </form>
      )}

      {activeTab === 'security' && (
        <div className="space-y-6">
          {/* Change Password */}
          <form onSubmit={handlePasswordSubmit} className="card space-y-6">
            <h2 className="text-lg font-semibold text-gray-900">Change Password</h2>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">Current Password</label>
              <div className="mt-1 relative">
                <input
                  type={showPasswords.old ? 'text' : 'password'}
                  name="old_password"
                  value={passwordData.old_password}
                  onChange={handlePasswordChange}
                  className="block w-full pr-10 rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onClick={() => setShowPasswords(prev => ({ ...prev, old: !prev.old }))}
                >
                  {showPasswords.old ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                </button>
              </div>
              {errors.old_password && <p className="mt-1 text-sm text-danger-600">{errors.old_password}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">New Password</label>
              <div className="mt-1 relative">
                <input
                  type={showPasswords.new ? 'text' : 'password'}
                  name="new_password"
                  value={passwordData.new_password}
                  onChange={handlePasswordChange}
                  className="block w-full pr-10 rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onClick={() => setShowPasswords(prev => ({ ...prev, new: !prev.new }))}
                >
                  {showPasswords.new ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                </button>
              </div>
              {errors.new_password && <p className="mt-1 text-sm text-danger-600">{errors.new_password}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Confirm New Password</label>
              <div className="mt-1 relative">
                <input
                  type={showPasswords.confirm ? 'text' : 'password'}
                  name="new_password_confirm"
                  value={passwordData.new_password_confirm}
                  onChange={handlePasswordChange}
                  className="block w-full pr-10 rounded-lg border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onClick={() => setShowPasswords(prev => ({ ...prev, confirm: !prev.confirm }))}
                >
                  {showPasswords.confirm ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                </button>
              </div>
              {errors.new_password_confirm && <p className="mt-1 text-sm text-danger-600">{errors.new_password_confirm}</p>}
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={loading}
                className="btn-primary"
              >
                {loading ? 'Changing...' : 'Change Password'}
              </button>
            </div>
          </form>

          {/* Delete Account */}
          <div className="card">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Delete Account</h2>
            <p className="text-gray-600 mb-4">
              Once you delete your account, there is no going back. Please be certain.
            </p>
            <button
              onClick={handleDeleteAccount}
              className="btn-danger flex items-center space-x-2"
            >
              <Trash2 className="w-4 h-4" />
              <span>Delete Account</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Profile; 