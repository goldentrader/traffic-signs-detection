import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';
import jwtDecode from 'jwt-decode';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [tokens, setTokens] = useState(() => {
    const accessToken = localStorage.getItem('access_token');
    const refreshToken = localStorage.getItem('refresh_token');
    return accessToken && refreshToken ? { access: accessToken, refresh: refreshToken } : null;
  });

  // Configure axios defaults
  useEffect(() => {
    if (tokens?.access) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${tokens.access}`;
    } else {
      delete axios.defaults.headers.common['Authorization'];
    }
  }, [tokens]);

  // Check if token is expired
  const isTokenExpired = (token) => {
    if (!token) return true;
    try {
      const decoded = jwtDecode(token);
      return decoded.exp * 1000 < Date.now();
    } catch {
      return true;
    }
  };

  // Refresh access token
  const refreshAccessToken = async () => {
    if (!tokens?.refresh || isTokenExpired(tokens.refresh)) {
      logout();
      return null;
    }

    try {
      const response = await axios.post('/api/auth/token/refresh/', {
        refresh: tokens.refresh
      });
      
      const newTokens = {
        access: response.data.access,
        refresh: tokens.refresh
      };
      
      setTokens(newTokens);
      localStorage.setItem('access_token', newTokens.access);
      return newTokens.access;
    } catch (error) {
      logout();
      return null;
    }
  };

  // Setup axios interceptors for automatic token refresh
  useEffect(() => {
    const requestInterceptor = axios.interceptors.request.use(
      async (config) => {
        if (tokens?.access && isTokenExpired(tokens.access)) {
          const newAccessToken = await refreshAccessToken();
          if (newAccessToken) {
            config.headers.Authorization = `Bearer ${newAccessToken}`;
          }
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    const responseInterceptor = axios.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401 && tokens?.access) {
          const newAccessToken = await refreshAccessToken();
          if (newAccessToken) {
            error.config.headers.Authorization = `Bearer ${newAccessToken}`;
            return axios.request(error.config);
          }
        }
        return Promise.reject(error);
      }
    );

    return () => {
      axios.interceptors.request.eject(requestInterceptor);
      axios.interceptors.response.eject(responseInterceptor);
    };
  }, [tokens]);

  // Load user data on mount
  useEffect(() => {
    const loadUser = async () => {
      if (tokens?.access && !isTokenExpired(tokens.access)) {
        try {
          const response = await axios.get('/api/auth/profile/');
          setUser(response.data);
        } catch (error) {
          console.error('Failed to load user:', error);
          logout();
        }
      }
      setLoading(false);
    };

    loadUser();
  }, []);

  const login = async (username, password) => {
    try {
      const response = await axios.post('/api/auth/login/', {
        username,
        password
      });

      const { user: userData, tokens: userTokens } = response.data;
      
      setUser(userData);
      setTokens(userTokens);
      
      localStorage.setItem('access_token', userTokens.access);
      localStorage.setItem('refresh_token', userTokens.refresh);
      
      return { success: true, user: userData };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.non_field_errors?.[0] || 'Login failed'
      };
    }
  };

  const register = async (userData) => {
    try {
      const response = await axios.post('/api/auth/register/', userData);
      
      const { user: newUser, tokens: userTokens } = response.data;
      
      setUser(newUser);
      setTokens(userTokens);
      
      localStorage.setItem('access_token', userTokens.access);
      localStorage.setItem('refresh_token', userTokens.refresh);
      
      return { success: true, user: newUser };
    } catch (error) {
      return {
        success: false,
        errors: error.response?.data || { general: 'Registration failed' }
      };
    }
  };

  const logout = async () => {
    try {
      if (tokens?.refresh) {
        await axios.post('/api/auth/logout/', {
          refresh_token: tokens.refresh
        });
      }
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setUser(null);
      setTokens(null);
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      delete axios.defaults.headers.common['Authorization'];
    }
  };

  const updateProfile = async (profileData) => {
    try {
      const response = await axios.put('/api/auth/profile/update/', profileData);
      setUser(response.data.user);
      return { success: true, user: response.data.user };
    } catch (error) {
      return {
        success: false,
        errors: error.response?.data || { general: 'Update failed' }
      };
    }
  };

  const value = {
    user,
    tokens,
    loading,
    login,
    register,
    logout,
    updateProfile,
    isAuthenticated: !!user,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}; 