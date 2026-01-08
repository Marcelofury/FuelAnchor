/**
 * Stations Screen - Find nearby fuel stations
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import * as Location from 'expo-location';
import { useTheme } from '../hooks/useTheme';
import { stationAPI } from '../services/api';

interface Station {
  id: string;
  name: string;
  address: string;
  distance: number;
  fuelPrice: number;
  isOpen: boolean;
  rating: number;
}

export default function StationsScreen() {
  const navigation = useNavigation<any>();
  const { theme } = useTheme();
  const [stations, setStations] = useState<Station[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [location, setLocation] = useState<Location.LocationObject | null>(null);

  useEffect(() => {
    loadStations();
  }, []);

  const loadStations = async () => {
    try {
      // Request location permission
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status === 'granted') {
        const loc = await Location.getCurrentPositionAsync({});
        setLocation(loc);
      }

      // Mock stations for demo
      const mockStations: Station[] = [
        { id: '1', name: 'TotalEnergies Westlands', address: 'Waiyaki Way, Nairobi', distance: 1.2, fuelPrice: 180.50, isOpen: true, rating: 4.5 },
        { id: '2', name: 'Shell Karen', address: 'Ngong Road, Nairobi', distance: 3.5, fuelPrice: 179.90, isOpen: true, rating: 4.2 },
        { id: '3', name: 'Rubis Thika Road', address: 'Thika Superhighway', distance: 5.8, fuelPrice: 178.00, isOpen: true, rating: 4.0 },
        { id: '4', name: 'Oilibya Junction', address: 'Mombasa Road', distance: 7.2, fuelPrice: 177.50, isOpen: false, rating: 3.8 },
        { id: '5', name: 'Hashi Energy', address: 'Lang\'ata Road', distance: 4.1, fuelPrice: 176.00, isOpen: true, rating: 4.3 },
      ];

      setStations(mockStations);
    } catch (error) {
      console.error('Failed to load stations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredStations = stations.filter(station =>
    station.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    station.address.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const renderStation = ({ item }: { item: Station }) => (
    <TouchableOpacity
      style={styles.stationCard}
      onPress={() => navigation.navigate('StationDetail', { station: item })}
    >
      <View style={styles.stationInfo}>
        <View style={styles.stationHeader}>
          <Text style={styles.stationName}>{item.name}</Text>
          <View style={[styles.statusBadge, { backgroundColor: item.isOpen ? theme.colors.success : theme.colors.error }]}>
            <Text style={styles.statusText}>{item.isOpen ? 'Open' : 'Closed'}</Text>
          </View>
        </View>
        <Text style={styles.stationAddress}>{item.address}</Text>
        <View style={styles.stationMeta}>
          <View style={styles.metaItem}>
            <Ionicons name="location" size={14} color={theme.colors.textSecondary} />
            <Text style={styles.metaText}>{item.distance} km</Text>
          </View>
          <View style={styles.metaItem}>
            <Ionicons name="star" size={14} color={theme.colors.accent} />
            <Text style={styles.metaText}>{item.rating}</Text>
          </View>
          <View style={styles.metaItem}>
            <Text style={styles.priceText}>KES {item.fuelPrice}/L</Text>
          </View>
        </View>
      </View>
      <Ionicons name="chevron-forward" size={20} color={theme.colors.textSecondary} />
    </TouchableOpacity>
  );

  const styles = createStyles(theme);

  return (
    <View style={styles.container}>
      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={20} color={theme.colors.textSecondary} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search stations..."
          placeholderTextColor={theme.colors.textSecondary}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity onPress={() => setSearchQuery('')}>
            <Ionicons name="close-circle" size={20} color={theme.colors.textSecondary} />
          </TouchableOpacity>
        )}
      </View>

      {/* Filter Tabs */}
      <View style={styles.filterTabs}>
        <TouchableOpacity style={[styles.filterTab, styles.filterTabActive]}>
          <Text style={styles.filterTabTextActive}>Nearby</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.filterTab}>
          <Text style={styles.filterTabText}>Cheapest</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.filterTab}>
          <Text style={styles.filterTabText}>Highest Rated</Text>
        </TouchableOpacity>
      </View>

      {/* Station List */}
      {isLoading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
        </View>
      ) : (
        <FlatList
          data={filteredStations}
          renderItem={renderStation}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="location-outline" size={48} color={theme.colors.textSecondary} />
              <Text style={styles.emptyText}>No stations found</Text>
            </View>
          }
        />
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: theme.spacing.md,
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
    height: 48,
  },
  searchInput: {
    flex: 1,
    marginLeft: theme.spacing.sm,
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
  },
  filterTabs: {
    flexDirection: 'row',
    paddingHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  filterTab: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
  },
  filterTabActive: {
    backgroundColor: theme.colors.primary,
  },
  filterTabText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  filterTabTextActive: {
    fontSize: theme.fontSize.sm,
    color: '#fff',
    fontWeight: '600',
  },
  listContent: {
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
  },
  stationCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
  },
  stationInfo: {
    flex: 1,
  },
  stationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.xs,
  },
  stationName: {
    fontSize: theme.fontSize.md,
    fontWeight: '600',
    color: theme.colors.text,
    flex: 1,
  },
  statusBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.full,
  },
  statusText: {
    fontSize: theme.fontSize.xs,
    color: '#fff',
    fontWeight: '600',
  },
  stationAddress: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.sm,
  },
  stationMeta: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  metaText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.textSecondary,
  },
  priceText: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 100,
  },
  emptyText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.textSecondary,
    marginTop: theme.spacing.md,
  },
});
