/**
 * Profile Screen - User settings and account management
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  Image,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../hooks/useTheme';
import { useAuth } from '../hooks/useAuth';

export default function ProfileScreen() {
  const { theme, toggleTheme, isDark } = useTheme();
  const { user, logout } = useAuth();
  const [notifications, setNotifications] = useState(true);
  const [biometrics, setBiometrics] = useState(false);

  const handleLogout = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to logout?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Logout', style: 'destructive', onPress: logout },
      ]
    );
  };

  const handleExportKeys = () => {
    Alert.alert(
      'Export Secret Key',
      'Warning: Your secret key provides full access to your wallet. Never share it with anyone.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Show Key', style: 'destructive', onPress: () => {
          // In a real app, show the secret key securely
          Alert.alert('Secret Key', 'S***...***K');
        }},
      ]
    );
  };

  const styles = createStyles(theme);

  const menuSections = [
    {
      title: 'Account',
      items: [
        { 
          icon: 'person-outline', 
          label: 'Personal Information', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'business-outline', 
          label: 'Fleet Association', 
          value: 'Alpha Fleet Ltd',
          onPress: () => {} 
        },
        { 
          icon: 'card-outline', 
          label: 'Payment Methods', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'document-text-outline', 
          label: 'KYC Verification', 
          value: 'Verified',
          valueColor: theme.colors.success,
          onPress: () => {} 
        },
      ],
    },
    {
      title: 'Security',
      items: [
        { 
          icon: 'key-outline', 
          label: 'Export Secret Key', 
          onPress: handleExportKeys,
          value: undefined 
        },
        { 
          icon: 'lock-closed-outline', 
          label: 'Change PIN', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'finger-print-outline', 
          label: 'Biometric Login', 
          toggle: true,
          value: biometrics,
          onToggle: setBiometrics,
          onPress: () => {} 
        },
      ],
    },
    {
      title: 'Preferences',
      items: [
        { 
          icon: 'notifications-outline', 
          label: 'Push Notifications', 
          toggle: true,
          value: notifications,
          onToggle: setNotifications,
          onPress: () => {} 
        },
        { 
          icon: 'moon-outline', 
          label: 'Dark Mode', 
          toggle: true,
          value: isDark,
          onToggle: toggleTheme,
          onPress: () => {} 
        },
        { 
          icon: 'language-outline', 
          label: 'Language', 
          value: 'English',
          onPress: () => {} 
        },
        { 
          icon: 'cash-outline', 
          label: 'Currency', 
          value: 'KES',
          onPress: () => {} 
        },
      ],
    },
    {
      title: 'Support',
      items: [
        { 
          icon: 'help-circle-outline', 
          label: 'Help Center', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'chatbubble-outline', 
          label: 'Contact Support', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'star-outline', 
          label: 'Rate App', 
          onPress: () => {},
          value: undefined 
        },
        { 
          icon: 'information-circle-outline', 
          label: 'About', 
          value: 'v1.0.0',
          onPress: () => {} 
        },
      ],
    },
  ];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Profile Header */}
      <View style={styles.header}>
        <View style={styles.avatarContainer}>
          {user?.avatar ? (
            <Image source={{ uri: user.avatar }} style={styles.avatar} />
          ) : (
            <View style={styles.avatarPlaceholder}>
              <Text style={styles.avatarText}>
                {user?.name?.[0] || 'U'}
              </Text>
            </View>
          )}
          <TouchableOpacity style={styles.editAvatarButton}>
            <Ionicons name="camera" size={16} color="#fff" />
          </TouchableOpacity>
        </View>
        <Text style={styles.userName}>{user?.name || 'User'}</Text>
        <Text style={styles.userEmail}>{user?.email || 'user@example.com'}</Text>
        <View style={styles.walletBadge}>
          <Ionicons name="wallet-outline" size={14} color={theme.colors.primary} />
          <Text style={styles.walletAddress}>
            {user?.stellarPublicKey?.substring(0, 8) || 'GD2X'}...
            {user?.stellarPublicKey?.slice(-4) || '7HKL'}
          </Text>
          <TouchableOpacity>
            <Ionicons name="copy-outline" size={14} color={theme.colors.primary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Menu Sections */}
      {menuSections.map((section, sIndex) => (
        <View key={sIndex} style={styles.section}>
          <Text style={styles.sectionTitle}>{section.title}</Text>
          <View style={styles.menuCard}>
            {section.items.map((item, iIndex) => (
              <TouchableOpacity
                key={iIndex}
                style={[
                  styles.menuItem,
                  iIndex < section.items.length - 1 && styles.menuItemBorder,
                ]}
                onPress={item.toggle ? undefined : item.onPress}
                activeOpacity={item.toggle ? 1 : 0.7}
              >
                <View style={styles.menuItemLeft}>
                  <Ionicons 
                    name={item.icon as any} 
                    size={22} 
                    color={theme.colors.textSecondary} 
                  />
                  <Text style={styles.menuItemLabel}>{item.label}</Text>
                </View>
                {item.toggle ? (
                  <Switch
                    value={item.value as boolean}
                    onValueChange={item.onToggle}
                    trackColor={{ 
                      false: theme.colors.border, 
                      true: theme.colors.primary 
                    }}
                    thumbColor="#fff"
                  />
                ) : (
                  <View style={styles.menuItemRight}>
                    {item.value && (
                      <Text style={[
                        styles.menuItemValue,
                        item.valueColor && { color: item.valueColor }
                      ]}>
                        {item.value}
                      </Text>
                    )}
                    <Ionicons 
                      name="chevron-forward" 
                      size={20} 
                      color={theme.colors.textSecondary} 
                    />
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>
        </View>
      ))}

      {/* Logout Button */}
      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <Ionicons name="log-out-outline" size={22} color={theme.colors.error} />
        <Text style={styles.logoutText}>Logout</Text>
      </TouchableOpacity>

      {/* Footer */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>FuelAnchor v1.0.0</Text>
        <Text style={styles.footerText}>© 2024 FuelAnchor Technologies</Text>
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
    paddingTop: 60,
    paddingBottom: theme.spacing.xxl,
  },
  header: {
    alignItems: 'center',
    paddingVertical: theme.spacing.xl,
    paddingHorizontal: theme.spacing.md,
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: theme.spacing.md,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
  },
  avatarPlaceholder: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 40,
    fontWeight: 'bold',
    color: '#fff',
  },
  editAvatarButton: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: theme.colors.background,
  },
  userName: {
    fontSize: theme.fontSize.xl,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  userEmail: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.sm,
  },
  walletBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    gap: theme.spacing.xs,
  },
  walletAddress: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  section: {
    marginBottom: theme.spacing.md,
    paddingHorizontal: theme.spacing.md,
  },
  sectionTitle: {
    fontSize: theme.fontSize.sm,
    fontWeight: '600',
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.sm,
    textTransform: 'uppercase',
    marginLeft: theme.spacing.sm,
  },
  menuCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.md,
  },
  menuItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  menuItemLabel: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
  },
  menuItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  menuItemValue: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: theme.spacing.md,
    marginTop: theme.spacing.md,
    paddingVertical: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    gap: theme.spacing.sm,
  },
  logoutText: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.error,
  },
  footer: {
    alignItems: 'center',
    marginTop: theme.spacing.xl,
    paddingHorizontal: theme.spacing.md,
  },
  footerText: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.xs,
  },
});
