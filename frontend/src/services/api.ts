/**
 * API Service Configuration
 */

import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  async (config) => {
    const token = await SecureStore.getItemAsync('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If 401 and not already retrying, try to refresh token
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = await SecureStore.getItemAsync('refresh_token');
        if (refreshToken) {
          const response = await api.post('/auth/refresh', { refreshToken });
          const { token } = response.data.data;

          await SecureStore.setItemAsync('auth_token', token);
          originalRequest.headers.Authorization = `Bearer ${token}`;

          return api(originalRequest);
        }
      } catch (refreshError) {
        // Refresh failed, clear auth and redirect to login
        await SecureStore.deleteItemAsync('auth_token');
        await SecureStore.deleteItemAsync('refresh_token');
        await SecureStore.deleteItemAsync('user_data');
      }
    }

    return Promise.reject(error);
  }
);

// API Methods

export const authAPI = {
  login: (email: string, password: string) => 
    api.post('/auth/login', { email, password }),
  
  register: (data: any) => 
    api.post('/auth/register', data),
  
  refresh: (refreshToken: string) => 
    api.post('/auth/refresh', { refreshToken }),
  
  getProfile: () => 
    api.get('/auth/me'),
  
  establishTrustline: () => 
    api.post('/auth/trustline'),
};

export const walletAPI = {
  getBalance: (publicKey: string) => 
    api.get(`/stellar/balance/${publicKey}`),
  
  transfer: (data: { to: string; amount: number; memo?: string }) => 
    api.post('/stellar/transfer', data),
  
  getTransactions: (publicKey: string, limit = 20) => 
    api.get(`/stellar/transactions/${publicKey}?limit=${limit}`),
};

export const fleetAPI = {
  getFleets: () => 
    api.get('/fleet'),
  
  getFleet: (fleetId: string) => 
    api.get(`/fleet/${fleetId}`),
  
  createFleet: (data: any) => 
    api.post('/fleet', data),
  
  purchaseFuel: (fleetId: string, data: any) => 
    api.post(`/fleet/${fleetId}/purchase`, data),
  
  addDriver: (fleetId: string, data: any) => 
    api.post(`/fleet/${fleetId}/drivers`, data),
  
  distributeTokens: (fleetId: string, distributions: any[]) => 
    api.post(`/fleet/${fleetId}/distribute`, { distributions }),
  
  getAnalytics: (fleetId: string, period = 'week') => 
    api.get(`/fleet/${fleetId}/analytics?period=${period}`),
};

export const stationAPI = {
  getStations: (params?: { country?: string; lat?: number; lng?: number; radius?: number }) => 
    api.get('/stations', { params }),
  
  getStation: (stationId: string) => 
    api.get(`/stations/${stationId}`),
  
  registerStation: (data: any) => 
    api.post('/stations', data),
  
  updatePrices: (stationId: string, fuelTypes: any[]) => 
    api.patch(`/stations/${stationId}/prices`, { fuelTypes }),
  
  redeemFuel: (stationId: string, data: any) => 
    api.post(`/stations/${stationId}/redeem`, data),
};

export const creditAPI = {
  getScore: () => 
    api.get('/credit/score'),
  
  getFactors: () => 
    api.get('/credit/factors'),
  
  getEligibility: () => 
    api.get('/credit/eligibility'),
  
  simulateScore: (data: any) => 
    api.post('/credit/simulate', data),
};

export const driverAPI = {
  getProfile: () => 
    api.get('/drivers/profile'),
  
  getLimits: () => 
    api.get('/drivers/limits'),
  
  getTransactions: () => 
    api.get('/drivers/transactions'),
  
  getNearbyStations: (lat: number, lng: number, radius = 10) => 
    api.get(`/drivers/stations?lat=${lat}&lng=${lng}&radius=${radius}`),
};

export default api;
