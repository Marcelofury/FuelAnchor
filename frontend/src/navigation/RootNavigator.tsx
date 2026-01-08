/**
 * Root Navigation Configuration
 */

import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../hooks/useAuth';

// Auth Screens
import LoginScreen from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import OnboardingScreen from '../screens/auth/OnboardingScreen';

// Main Screens
import HomeScreen from '../screens/HomeScreen';
import WalletScreen from '../screens/WalletScreen';
import StationsScreen from '../screens/StationsScreen';
import CreditScreen from '../screens/CreditScreen';
import ProfileScreen from '../screens/ProfileScreen';

// Additional Screens
import TransactionHistoryScreen from '../screens/TransactionHistoryScreen';
import ScanScreen from '../screens/ScanScreen';
import TransferScreen from '../screens/TransferScreen';
import StationDetailScreen from '../screens/StationDetailScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap = 'home';

          switch (route.name) {
            case 'Home':
              iconName = focused ? 'home' : 'home-outline';
              break;
            case 'Wallet':
              iconName = focused ? 'wallet' : 'wallet-outline';
              break;
            case 'Scan':
              iconName = focused ? 'scan-circle' : 'scan-circle-outline';
              break;
            case 'Stations':
              iconName = focused ? 'location' : 'location-outline';
              break;
            case 'Credit':
              iconName = focused ? 'trending-up' : 'trending-up-outline';
              break;
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#1E3A5F',
        tabBarInactiveTintColor: 'gray',
        headerShown: false,
      })}
    >
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Wallet" component={WalletScreen} />
      <Tab.Screen 
        name="Scan" 
        component={ScanScreen}
        options={{
          tabBarLabel: 'Pay',
        }}
      />
      <Tab.Screen name="Stations" component={StationsScreen} />
      <Tab.Screen name="Credit" component={CreditScreen} />
    </Tab.Navigator>
  );
}

export default function RootNavigator() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return null; // Or a loading screen
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!isAuthenticated ? (
        // Auth Stack
        <>
          <Stack.Screen name="Onboarding" component={OnboardingScreen} />
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </>
      ) : (
        // Main App Stack
        <>
          <Stack.Screen name="MainTabs" component={MainTabs} />
          <Stack.Screen 
            name="TransactionHistory" 
            component={TransactionHistoryScreen}
            options={{ headerShown: true, title: 'Transaction History' }}
          />
          <Stack.Screen 
            name="Transfer" 
            component={TransferScreen}
            options={{ headerShown: true, title: 'Transfer FUEL' }}
          />
          <Stack.Screen 
            name="StationDetail" 
            component={StationDetailScreen}
            options={{ headerShown: true, title: 'Station Details' }}
          />
          <Stack.Screen 
            name="Profile" 
            component={ProfileScreen}
            options={{ headerShown: true, title: 'Profile' }}
          />
        </>
      )}
    </Stack.Navigator>
  );
}
