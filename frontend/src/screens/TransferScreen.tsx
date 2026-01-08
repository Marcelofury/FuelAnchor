/**
 * Transfer Screen - Send FUEL tokens to another wallet
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../hooks/useTheme';
import { walletAPI } from '../services/api';

interface RecentRecipient {
  id: string;
  name: string;
  wallet: string;
  avatar?: string;
}

export default function TransferScreen() {
  const { theme } = useTheme();
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  const [memo, setMemo] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [balance] = useState(4520); // Would come from state/API

  const recentRecipients: RecentRecipient[] = [
    { id: '1', name: 'John Driver', wallet: 'GD2X...7HKL' },
    { id: '2', name: 'Fleet Alpha', wallet: 'GA4K...9MNP' },
    { id: '3', name: 'Sarah M.', wallet: 'GC8Y...2QRS' },
  ];

  const quickAmounts = [100, 500, 1000, 2000];

  const handleTransfer = async () => {
    if (!recipient.trim()) {
      Alert.alert('Error', 'Please enter a recipient address');
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      Alert.alert('Error', 'Please enter a valid amount');
      return;
    }

    if (parseFloat(amount) > balance) {
      Alert.alert('Error', 'Insufficient balance');
      return;
    }

    Alert.alert(
      'Confirm Transfer',
      `Send ${amount} FUEL to ${recipient.substring(0, 8)}...?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Confirm', 
          onPress: async () => {
            setIsLoading(true);
            try {
              await walletAPI.transfer(recipient, parseFloat(amount), memo);
              Alert.alert('Success', 'Transfer completed successfully');
              setRecipient('');
              setAmount('');
              setMemo('');
            } catch (error) {
              Alert.alert('Error', 'Transfer failed. Please try again.');
            } finally {
              setIsLoading(false);
            }
          }
        },
      ]
    );
  };

  const selectRecipient = (wallet: string) => {
    setRecipient(wallet);
  };

  const selectQuickAmount = (value: number) => {
    setAmount(value.toString());
  };

  const styles = createStyles(theme);

  return (
    <KeyboardAvoidingView 
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView 
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        {/* Balance Card */}
        <View style={styles.balanceCard}>
          <Text style={styles.balanceLabel}>Available Balance</Text>
          <Text style={styles.balanceValue}>{balance.toLocaleString()} FUEL</Text>
        </View>

        {/* Recipient Input */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recipient</Text>
          <View style={styles.inputContainer}>
            <Ionicons name="wallet-outline" size={20} color={theme.colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Enter Stellar wallet address"
              placeholderTextColor={theme.colors.textSecondary}
              value={recipient}
              onChangeText={setRecipient}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <TouchableOpacity style={styles.scanIcon}>
              <Ionicons name="qr-code-outline" size={20} color={theme.colors.primary} />
            </TouchableOpacity>
          </View>
        </View>

        {/* Recent Recipients */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {recentRecipients.map((r) => (
              <TouchableOpacity
                key={r.id}
                style={styles.recipientChip}
                onPress={() => selectRecipient(r.wallet)}
              >
                <View style={styles.recipientAvatar}>
                  <Text style={styles.recipientInitial}>{r.name[0]}</Text>
                </View>
                <View>
                  <Text style={styles.recipientName}>{r.name}</Text>
                  <Text style={styles.recipientWallet}>{r.wallet}</Text>
                </View>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Amount Input */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Amount</Text>
          <View style={styles.amountContainer}>
            <TextInput
              style={styles.amountInput}
              placeholder="0"
              placeholderTextColor={theme.colors.textSecondary}
              value={amount}
              onChangeText={setAmount}
              keyboardType="numeric"
            />
            <Text style={styles.amountUnit}>FUEL</Text>
          </View>
          <View style={styles.quickAmounts}>
            {quickAmounts.map((value) => (
              <TouchableOpacity
                key={value}
                style={[
                  styles.quickAmountButton,
                  amount === value.toString() && styles.quickAmountButtonActive
                ]}
                onPress={() => selectQuickAmount(value)}
              >
                <Text style={[
                  styles.quickAmountText,
                  amount === value.toString() && styles.quickAmountTextActive
                ]}>
                  {value}
                </Text>
              </TouchableOpacity>
            ))}
            <TouchableOpacity
              style={[
                styles.quickAmountButton,
                amount === balance.toString() && styles.quickAmountButtonActive
              ]}
              onPress={() => selectQuickAmount(balance)}
            >
              <Text style={[
                styles.quickAmountText,
                amount === balance.toString() && styles.quickAmountTextActive
              ]}>
                Max
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Memo */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Memo (Optional)</Text>
          <View style={styles.inputContainer}>
            <Ionicons name="document-text-outline" size={20} color={theme.colors.textSecondary} />
            <TextInput
              style={styles.input}
              placeholder="Add a note"
              placeholderTextColor={theme.colors.textSecondary}
              value={memo}
              onChangeText={setMemo}
            />
          </View>
        </View>

        {/* Transaction Summary */}
        {amount && parseFloat(amount) > 0 && (
          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Transaction Summary</Text>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Amount</Text>
              <Text style={styles.summaryValue}>{amount} FUEL</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Network Fee</Text>
              <Text style={styles.summaryValue}>0.00001 XLM</Text>
            </View>
            <View style={[styles.summaryRow, styles.summaryTotal]}>
              <Text style={styles.summaryTotalLabel}>Total</Text>
              <Text style={styles.summaryTotalValue}>{amount} FUEL</Text>
            </View>
          </View>
        )}
      </ScrollView>

      {/* Transfer Button */}
      <View style={styles.footer}>
        <TouchableOpacity
          style={[
            styles.transferButton,
            (!recipient || !amount || isLoading) && styles.transferButtonDisabled
          ]}
          onPress={handleTransfer}
          disabled={!recipient || !amount || isLoading}
        >
          {isLoading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <>
              <Ionicons name="send" size={20} color="#fff" />
              <Text style={styles.transferButtonText}>Send FUEL</Text>
            </>
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const createStyles = (theme: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  scrollView: {
    flex: 1,
  },
  content: {
    padding: theme.spacing.md,
    paddingTop: 60,
    paddingBottom: 100,
  },
  balanceCard: {
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    marginBottom: theme.spacing.lg,
  },
  balanceLabel: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: theme.fontSize.sm,
    marginBottom: theme.spacing.xs,
  },
  balanceValue: {
    color: '#fff',
    fontSize: theme.fontSize.xxl,
    fontWeight: 'bold',
  },
  section: {
    marginBottom: theme.spacing.lg,
  },
  sectionTitle: {
    fontSize: theme.fontSize.sm,
    fontWeight: '600',
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.sm,
    textTransform: 'uppercase',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  input: {
    flex: 1,
    paddingVertical: theme.spacing.md,
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
  },
  scanIcon: {
    padding: theme.spacing.sm,
  },
  recipientChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.sm,
    marginRight: theme.spacing.sm,
    gap: theme.spacing.sm,
  },
  recipientAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  recipientInitial: {
    color: '#fff',
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
  },
  recipientName: {
    fontSize: theme.fontSize.sm,
    fontWeight: '500',
    color: theme.colors.text,
  },
  recipientWallet: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.textSecondary,
  },
  amountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  amountInput: {
    flex: 1,
    paddingVertical: theme.spacing.lg,
    fontSize: 32,
    fontWeight: 'bold',
    color: theme.colors.text,
  },
  amountUnit: {
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
    color: theme.colors.textSecondary,
  },
  quickAmounts: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  quickAmountButton: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  quickAmountButtonActive: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  quickAmountText: {
    fontSize: theme.fontSize.sm,
    fontWeight: '600',
    color: theme.colors.text,
  },
  quickAmountTextActive: {
    color: '#fff',
  },
  summaryCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
  },
  summaryTitle: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: theme.spacing.md,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  summaryLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  summaryValue: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
  },
  summaryTotal: {
    marginTop: theme.spacing.sm,
    paddingTop: theme.spacing.sm,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  summaryTotalLabel: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.text,
  },
  summaryTotalValue: {
    fontSize: theme.fontSize.md,
    fontWeight: 'bold',
    color: theme.colors.primary,
  },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  transferButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    gap: theme.spacing.sm,
  },
  transferButtonDisabled: {
    opacity: 0.5,
  },
  transferButtonText: {
    color: '#fff',
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
  },
});
