/**
 * Scan Screen - NFC/QR Code scanning for fuel redemption
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Vibration,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../hooks/useTheme';

type ScanMode = 'nfc' | 'qr';

export default function ScanScreen() {
  const { theme } = useTheme();
  const [scanMode, setScanMode] = useState<ScanMode>('nfc');
  const [isScanning, setIsScanning] = useState(false);
  const [nfcSupported, setNfcSupported] = useState(true);

  useEffect(() => {
    checkNfcSupport();
    return () => {
      stopScanning();
    };
  }, []);

  const checkNfcSupport = async () => {
    try {
      // In a real app, we'd check NFC support here
      // import NfcManager from 'react-native-nfc-manager';
      // const supported = await NfcManager.isSupported();
      setNfcSupported(Platform.OS !== 'web');
    } catch (error) {
      setNfcSupported(false);
    }
  };

  const startNfcScan = async () => {
    try {
      setIsScanning(true);
      // In a real app:
      // await NfcManager.requestTechnology(NfcTech.Ndef);
      // const tag = await NfcManager.getTag();
      // processNfcTag(tag);
      
      // Simulate NFC scanning
      setTimeout(() => {
        Vibration.vibrate(100);
        handleSuccessfulScan({ type: 'nfc', data: 'station_001' });
      }, 3000);
    } catch (error) {
      console.error('NFC error:', error);
      setIsScanning(false);
      Alert.alert('NFC Error', 'Failed to read NFC tag. Please try again.');
    }
  };

  const startQrScan = async () => {
    setIsScanning(true);
    // In a real app, we'd use expo-barcode-scanner or expo-camera
    // For now, simulate QR scanning
    setTimeout(() => {
      Vibration.vibrate(100);
      handleSuccessfulScan({ type: 'qr', data: 'station_002' });
    }, 2000);
  };

  const stopScanning = () => {
    setIsScanning(false);
    // NfcManager.cancelTechnologyRequest();
  };

  const handleSuccessfulScan = (scanResult: { type: string; data: string }) => {
    setIsScanning(false);
    // Navigate to redemption screen with station data
    Alert.alert(
      'Station Found',
      `Scanned ${scanResult.type.toUpperCase()} successfully!\nStation ID: ${scanResult.data}`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Proceed to Pay', onPress: () => navigateToPayment(scanResult.data) },
      ]
    );
  };

  const navigateToPayment = (stationId: string) => {
    // In a real app, navigate to payment/redemption screen
    console.log('Navigating to payment for station:', stationId);
  };

  const styles = createStyles(theme);

  return (
    <View style={styles.container}>
      {/* Mode Selector */}
      <View style={styles.modeSelector}>
        <TouchableOpacity
          style={[styles.modeButton, scanMode === 'nfc' && styles.modeButtonActive]}
          onPress={() => setScanMode('nfc')}
          disabled={!nfcSupported}
        >
          <Ionicons 
            name="card-outline" 
            size={20} 
            color={scanMode === 'nfc' ? '#fff' : theme.colors.textSecondary} 
          />
          <Text style={[styles.modeText, scanMode === 'nfc' && styles.modeTextActive]}>
            NFC
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.modeButton, scanMode === 'qr' && styles.modeButtonActive]}
          onPress={() => setScanMode('qr')}
        >
          <Ionicons 
            name="qr-code-outline" 
            size={20} 
            color={scanMode === 'qr' ? '#fff' : theme.colors.textSecondary} 
          />
          <Text style={[styles.modeText, scanMode === 'qr' && styles.modeTextActive]}>
            QR Code
          </Text>
        </TouchableOpacity>
      </View>

      {/* Scan Area */}
      <View style={styles.scanArea}>
        {scanMode === 'nfc' ? (
          <View style={styles.nfcContainer}>
            <View style={[styles.nfcCircle, isScanning && styles.nfcCircleActive]}>
              <Ionicons 
                name="card" 
                size={80} 
                color={isScanning ? theme.colors.primary : theme.colors.textSecondary} 
              />
            </View>
            <Text style={styles.scanTitle}>
              {isScanning ? 'Scanning...' : 'Tap NFC Card'}
            </Text>
            <Text style={styles.scanDescription}>
              {isScanning 
                ? 'Hold your card near the phone'
                : 'Tap your FuelAnchor NFC card to the back of your phone to pay for fuel'
              }
            </Text>
          </View>
        ) : (
          <View style={styles.qrContainer}>
            <View style={styles.qrFrame}>
              <View style={[styles.qrCorner, styles.qrCornerTL]} />
              <View style={[styles.qrCorner, styles.qrCornerTR]} />
              <View style={[styles.qrCorner, styles.qrCornerBL]} />
              <View style={[styles.qrCorner, styles.qrCornerBR]} />
              {isScanning && (
                <View style={styles.scanLine} />
              )}
            </View>
            <Text style={styles.scanTitle}>
              {isScanning ? 'Scanning...' : 'Scan QR Code'}
            </Text>
            <Text style={styles.scanDescription}>
              {isScanning 
                ? 'Point your camera at the QR code'
                : 'Scan the QR code displayed at the fuel station'
              }
            </Text>
          </View>
        )}
      </View>

      {/* Action Button */}
      <View style={styles.actionContainer}>
        {!isScanning ? (
          <TouchableOpacity
            style={styles.scanButton}
            onPress={scanMode === 'nfc' ? startNfcScan : startQrScan}
          >
            <Ionicons 
              name={scanMode === 'nfc' ? 'scan' : 'camera'} 
              size={24} 
              color="#fff" 
            />
            <Text style={styles.scanButtonText}>
              {scanMode === 'nfc' ? 'Start NFC Scan' : 'Start Camera'}
            </Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
            style={[styles.scanButton, styles.cancelButton]}
            onPress={stopScanning}
          >
            <Ionicons name="close" size={24} color="#fff" />
            <Text style={styles.scanButtonText}>Cancel</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Help Section */}
      <View style={styles.helpSection}>
        <TouchableOpacity style={styles.helpItem}>
          <Ionicons name="help-circle-outline" size={20} color={theme.colors.primary} />
          <Text style={styles.helpText}>How to pay with NFC</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.helpItem}>
          <Ionicons name="location-outline" size={20} color={theme.colors.primary} />
          <Text style={styles.helpText}>Find nearby stations</Text>
        </TouchableOpacity>
      </View>

      {/* NFC Not Supported Warning */}
      {!nfcSupported && scanMode === 'nfc' && (
        <View style={styles.warningBanner}>
          <Ionicons name="warning-outline" size={20} color={theme.colors.warning} />
          <Text style={styles.warningText}>
            NFC is not supported on this device. Please use QR code scanning.
          </Text>
        </View>
      )}
    </View>
  );
}

const createStyles = (theme: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
    paddingTop: 60,
  },
  modeSelector: {
    flexDirection: 'row',
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.xs,
  },
  modeButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.sm,
    gap: theme.spacing.xs,
    borderRadius: theme.borderRadius.md,
  },
  modeButtonActive: {
    backgroundColor: theme.colors.primary,
  },
  modeText: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.textSecondary,
  },
  modeTextActive: {
    color: '#fff',
  },
  scanArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: theme.spacing.xl,
  },
  nfcContainer: {
    alignItems: 'center',
  },
  nfcCircle: {
    width: 180,
    height: 180,
    borderRadius: 90,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.xl,
    borderWidth: 3,
    borderColor: theme.colors.border,
  },
  nfcCircleActive: {
    borderColor: theme.colors.primary,
    shadowColor: theme.colors.primary,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 20,
    elevation: 10,
  },
  qrContainer: {
    alignItems: 'center',
  },
  qrFrame: {
    width: 250,
    height: 250,
    marginBottom: theme.spacing.xl,
    position: 'relative',
    backgroundColor: theme.colors.surface,
  },
  qrCorner: {
    position: 'absolute',
    width: 40,
    height: 40,
    borderColor: theme.colors.primary,
  },
  qrCornerTL: {
    top: 0,
    left: 0,
    borderTopWidth: 4,
    borderLeftWidth: 4,
  },
  qrCornerTR: {
    top: 0,
    right: 0,
    borderTopWidth: 4,
    borderRightWidth: 4,
  },
  qrCornerBL: {
    bottom: 0,
    left: 0,
    borderBottomWidth: 4,
    borderLeftWidth: 4,
  },
  qrCornerBR: {
    bottom: 0,
    right: 0,
    borderBottomWidth: 4,
    borderRightWidth: 4,
  },
  scanLine: {
    position: 'absolute',
    top: '50%',
    left: 20,
    right: 20,
    height: 2,
    backgroundColor: theme.colors.primary,
  },
  scanTitle: {
    fontSize: theme.fontSize.xl,
    fontWeight: '600',
    color: theme.colors.text,
    marginBottom: theme.spacing.sm,
    textAlign: 'center',
  },
  scanDescription: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  actionContainer: {
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.lg,
  },
  scanButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    gap: theme.spacing.sm,
  },
  cancelButton: {
    backgroundColor: theme.colors.error,
  },
  scanButtonText: {
    color: '#fff',
    fontSize: theme.fontSize.lg,
    fontWeight: '600',
  },
  helpSection: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: theme.spacing.xl,
    paddingVertical: theme.spacing.lg,
  },
  helpItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  helpText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.primary,
  },
  warningBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${theme.colors.warning}20`,
    padding: theme.spacing.md,
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    gap: theme.spacing.sm,
  },
  warningText: {
    flex: 1,
    fontSize: theme.fontSize.sm,
    color: theme.colors.warning,
  },
});
