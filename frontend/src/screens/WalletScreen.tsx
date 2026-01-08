/**
 * Wallet Screen
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Share,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import QRCode from 'react-native-qrcode-svg';
import { useAuth } from '../hooks/useAuth';
import { useTheme } from '../hooks/useTheme';
import { walletAPI } from '../services/api';

export default function WalletScreen() {
  const navigation = useNavigation<any>();
  const { user } = useAuth();
  const { theme } = useTheme();
  const [balance, setBalance] = useState('0');
  const [refreshing, setRefreshing] = useState(false);
  const [showQR, setShowQR] = useState(false);

  useEffect(() => {
    loadBalance();
  }, []);

  const loadBalance = async () => {
    try {
      if (user?.walletAddress) {
        const response = await walletAPI.getBalance(user.walletAddress);
        setBalance(response.data.data.balance);
      }
    } catch (error) {
      console.error('Failed to load balance:', error);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadBalance();
    setRefreshing(false);
  };

  const shareAddress = async () => {
    try {
      await Share.share({
        message: `My FuelAnchor wallet address: ${user?.walletAddress}`,
      });
    } catch (error) {
      console.error('Share error:', error);
    }
  };

  const formatBalance = (bal: string) => {
    const num = parseFloat(bal);
    return num.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  const formatAddress = (address: string) => {
    if (!address) return '';
    return `${address.slice(0, 8)}...${address.slice(-8)}`;
  };

  const styles = createStyles(theme);

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      {/* Balance Section */}
      <View style={styles.balanceSection}>
        <Text style={styles.balanceLabel}>FUEL Balance</Text>
        <Text style={styles.balanceAmount}>{formatBalance(balance)}</Text>
        <Text style={styles.balanceSubtext}>FUEL Tokens</Text>
        
        <TouchableOpacity 
          style={styles.addressContainer}
          onPress={shareAddress}
        >
          <Text style={styles.address}>{formatAddress(user?.walletAddress || '')}</Text>
          <Ionicons name="copy-outline" size={16} color={theme.colors.textSecondary} />
        </TouchableOpacity>
      </View>

      {/* Action Buttons */}
      <View style={styles.actions}>
        <TouchableOpacity 
          style={styles.actionButton}
          onPress={() => navigation.navigate('Transfer')}
        >
          <View style={[styles.actionIcon, { backgroundColor: theme.colors.primary }]}>
            <Ionicons name="arrow-up" size={24} color="#fff" />
          </View>
          <Text style={styles.actionLabel}>Send</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.actionButton}
          onPress={() => setShowQR(!showQR)}
        >
          <View style={[styles.actionIcon, { backgroundColor: theme.colors.success }]}>
            <Ionicons name="arrow-down" size={24} color="#fff" />
          </View>
          <Text style={styles.actionLabel}>Receive</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.actionButton}
          onPress={() => {/* Navigate to buy screen */}}
        >
          <View style={[styles.actionIcon, { backgroundColor: theme.colors.accent }]}>
            <Ionicons name="add" size={24} color="#fff" />
          </View>
          <Text style={styles.actionLabel}>Buy</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.actionButton}
          onPress={() => navigation.navigate('TransactionHistory')}
        >
          <View style={[styles.actionIcon, { backgroundColor: theme.colors.info }]}>
            <Ionicons name="time" size={24} color="#fff" />
          </View>
          <Text style={styles.actionLabel}>History</Text>
        </TouchableOpacity>
      </View>

      {/* QR Code Section */}
      {showQR && (
        <View style={styles.qrSection}>
          <Text style={styles.qrTitle}>Scan to receive FUEL</Text>
          <View style={styles.qrContainer}>
            <QRCode
              value={user?.walletAddress || 'no-address'}
              size={200}
              backgroundColor="white"
              color={theme.colors.primary}
            />
          </View>
          <Text style={styles.qrAddress}>{user?.walletAddress}</Text>
        </View>
      )}

      {/* Quick Stats */}
      <View style={styles.statsSection}>
        <Text style={styles.statsTitle}>This Month</Text>
        <View style={styles.statsGrid}>
          <View style={styles.statCard}>
            <Ionicons name="trending-up" size={24} color={theme.colors.success} />
            <Text style={styles.statValue}>+5,000</Text>
            <Text style={styles.statLabel}>Received</Text>
          </View>
          <View style={styles.statCard}>
            <Ionicons name="trending-down" size={24} color={theme.colors.error} />
            <Text style={styles.statValue}>-3,200</Text>
            <Text style={styles.statLabel}>Spent</Text>
          </View>
          <View style={styles.statCard}>
            <Ionicons name="flash" size={24} color={theme.colors.accent} />
            <Text style={styles.statValue}>24</Text>
            <Text style={styles.statLabel}>Transactions</Text>
          </View>
        </View>
      </View>

      {/* Info Card */}
      <View style={styles.infoCard}>
        <Ionicons name="information-circle" size={24} color={theme.colors.info} />
        <View style={styles.infoContent}>
          <Text style={styles.infoTitle}>About FUEL Tokens</Text>
          <Text style={styles.infoText}>
            FUEL tokens are backed 1:1 by prepaid fuel credits. Use them at any 
            partner station across East Africa. Build your credit score with every purchase!
          </Text>
        </View>
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
  balanceSection: {
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.xl,
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  balanceLabel: {
    fontSize: theme.fontSize.sm,
    color: 'rgba(255,255,255,0.8)',
    marginBottom: theme.spacing.xs,
  },
  balanceAmount: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#fff',
  },
  balanceSubtext: {
    fontSize: theme.fontSize.md,
    color: 'rgba(255,255,255,0.6)',
    marginTop: theme.spacing.xs,
  },
  addressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    marginTop: theme.spacing.md,
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  address: {
    fontSize: theme.fontSize.sm,
    color: '#fff',
    fontFamily: 'monospace',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: theme.spacing.lg,
  },
  actionButton: {
    alignItems: 'center',
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  actionLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
    fontWeight: '500',
  },
  qrSection: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  qrTitle: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    marginBottom: theme.spacing.md,
  },
  qrContainer: {
    padding: theme.spacing.md,
    backgroundColor: '#fff',
    borderRadius: theme.borderRadius.md,
  },
  qrAddress: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.textSecondary,
    marginTop: theme.spacing.md,
    fontFamily: 'monospace',
  },
  statsSection: {
    marginBottom: theme.spacing.lg,
  },
  statsTitle: {
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: theme.spacing.md,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  statCard: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    alignItems: 'center',
  },
  statValue: {
    fontSize: theme.fontSize.lg,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginTop: theme.spacing.sm,
  },
  statLabel: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.textSecondary,
    marginTop: theme.spacing.xs,
  },
  infoCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  infoContent: {
    flex: 1,
  },
  infoTitle: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  infoText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
    lineHeight: 20,
  },
});
