/**
 * Home Screen - Main Dashboard
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../hooks/useTheme';
import { walletAPI, creditAPI } from '../services/api';
import BalanceCard from '../components/BalanceCard';
import QuickActions from '../components/QuickActions';
import RecentTransactions from '../components/RecentTransactions';

export default function HomeScreen() {
  const navigation = useNavigation<any>();
  const { user } = useAuth();
  const { theme } = useTheme();
  const [balance, setBalance] = useState('0');
  const [creditScore, setCreditScore] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      if (user?.walletAddress) {
        const [balanceRes, creditRes] = await Promise.all([
          walletAPI.getBalance(user.walletAddress),
          creditAPI.getScore(),
        ]);
        setBalance(balanceRes.data.data.balance);
        setCreditScore(creditRes.data.data.score);
      }
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const styles = createStyles(theme);

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Hello, {user?.name?.split(' ')[0]} 👋</Text>
          <Text style={styles.subtitle}>Welcome to FuelAnchor</Text>
        </View>
        <TouchableOpacity 
          style={styles.profileButton}
          onPress={() => navigation.navigate('Profile')}
        >
          <Ionicons name="person-circle" size={40} color={theme.colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Balance Card */}
      <BalanceCard balance={balance} walletAddress={user?.walletAddress || ''} />

      {/* Credit Score Preview */}
      <TouchableOpacity 
        style={styles.creditCard}
        onPress={() => navigation.navigate('Credit')}
      >
        <View style={styles.creditCardContent}>
          <View>
            <Text style={styles.creditLabel}>Fuel Credit Score</Text>
            <Text style={styles.creditScore}>{creditScore || 'Build your score'}</Text>
          </View>
          <View style={styles.creditBadge}>
            <Ionicons 
              name={creditScore >= 500 ? 'checkmark-circle' : 'time'} 
              size={24} 
              color={creditScore >= 500 ? theme.colors.success : theme.colors.warning} 
            />
            <Text style={[
              styles.creditTier,
              { color: creditScore >= 500 ? theme.colors.success : theme.colors.warning }
            ]}>
              {creditScore >= 750 ? 'PLATINUM' : 
               creditScore >= 650 ? 'GOLD' : 
               creditScore >= 500 ? 'SILVER' : 
               creditScore > 0 ? 'BRONZE' : 'UNSCORED'}
            </Text>
          </View>
        </View>
        <Ionicons name="chevron-forward" size={20} color={theme.colors.textSecondary} />
      </TouchableOpacity>

      {/* Quick Actions */}
      <QuickActions />

      {/* Recent Transactions */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Recent Activity</Text>
          <TouchableOpacity onPress={() => navigation.navigate('TransactionHistory')}>
            <Text style={styles.seeAll}>See All</Text>
          </TouchableOpacity>
        </View>
        <RecentTransactions walletAddress={user?.walletAddress || ''} limit={5} />
      </View>
    </ScrollView>
  );
}

const createStyles = (theme: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  content: {
    padding: theme.spacing.md,
    paddingTop: 60,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  greeting: {
    fontSize: theme.fontSize.xxl,
    fontWeight: 'bold',
    color: theme.colors.text,
  },
  subtitle: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    marginTop: 4,
  },
  profileButton: {
    padding: theme.spacing.xs,
  },
  creditCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  creditCardContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.lg,
  },
  creditLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  creditScore: {
    fontSize: theme.fontSize.xl,
    fontWeight: 'bold',
    color: theme.colors.text,
  },
  creditBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  creditTier: {
    fontSize: theme.fontSize.sm,
    fontWeight: '600',
  },
  section: {
    marginTop: theme.spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
    color: theme.colors.text,
  },
  seeAll: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.primary,
    fontWeight: '500',
  },
});
