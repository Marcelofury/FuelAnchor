import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/api_config.dart';

class NearbyStationsScreen extends ConsumerStatefulWidget {
  const NearbyStationsScreen({super.key});

  @override
  ConsumerState<NearbyStationsScreen> createState() => _NearbyStationsScreenState();
}

class _NearbyStationsScreenState extends ConsumerState<NearbyStationsScreen> {
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;

  String _sortBy = 'distance'; // distance, price

  @override
  void initState() {
    super.initState();
    _loadNearbyStations();
  }

  Future<void> _loadNearbyStations() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        AppLogger.warning('Failed to get location, using default', e);
        // Default to Kampala coordinates
        position = Position(
          latitude: 0.3476,
          longitude: 32.5825,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      setState(() => _currentPosition = position);

      // Fetch stations from backend
      final supabase = SupabaseService.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        throw Exception('No authenticated session');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.nearbyStations}'
          '?lat=${position.latitude}'
          '&lng=${position.longitude}'
          '&radius=10',
        ),
        headers: ApiConfig.headers(authToken: session.accessToken),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stationsData = data['data']['stations'] as List;
        
        setState(() {
          _stations = stationsData.map((station) => {
            'name': station['name'] as String,
            'distance': station['distance'] as double,
            'dieselPrice': (station['fuelTypes'] as List)
                .firstWhere((ft) => ft['type'] == 'diesel',
                    orElse: () => {'pricePerLiter': 4850})['pricePerLiter'] as int,
            'petrolPrice': (station['fuelTypes'] as List)
                .firstWhere((ft) => ft['type'] == 'petrol',
                    orElse: () => {'pricePerLiter': 5200})['pricePerLiter'] as int,
            'rating': station['rating'] ?? 0.0,
            'open': true, // TODO: Add opening hours logic
            'verified': station['isVerified'] as bool,
            'address': station['address'] as String,
            'location': station['location'],
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load stations: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error loading stations', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to mock data
        _stations = [
          {
            'name': 'Shell Kampala Central',
            'distance': 1.2,
            'dieselPrice': 4850,
            'petrolPrice': 5200,
            'rating': 4.5,
            'open': true,
            'verified': true,
          },
          {
            'name': 'Total Nakasero',
            'distance': 2.3,
            'dieselPrice': 4800,
            'petrolPrice': 5150,
            'rating': 4.3,
            'open': true,
            'verified': true,
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          title: const Text('Nearby Stations'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricGreen),
              ),
              SizedBox(height: 16),
              Text('Finding nearby fuel stations...'),
            ],
          ),
        ),
      );
    }

    // Sort stations
    final sortedStations = List<Map<String, dynamic>>.from(_stations);
    if (_sortBy == 'distance') {
      sortedStations.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    } else {
      sortedStations.sort((a, b) => (a['dieselPrice'] as int).compareTo(b['dieselPrice'] as int));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: const Text('Nearby Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyStations,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.near_me, size: 20, color: _sortBy == 'distance' ? AppColors.electricGreen : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Sort by Distance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20, color: _sortBy == 'price' ? AppColors.electricGreen : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Sort by Price'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder
          Container(
            height: 250,
            color: Colors.grey[300],
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.map, size: 80, color: Colors.grey[500]),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search stations...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Centering on your location...')),
                      );
                    },
                    child: const Icon(Icons.my_location, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),

          // Station list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedStations.length,
              itemBuilder: (context, index) {
                final station = sortedStations[index];
                return _StationCard(
                  station: station,
                  onTap: () {
                    _showStationDetails(station);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStationDetails(Map<String, dynamic> station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (station['verified'])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: AppColors.electricGreen),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.near_me, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Text('${station['distance']} km away'),
                const SizedBox(width: 24),
                Icon(Icons.star, size: 18, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text('${station['rating']}'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Fuel Prices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PriceTile(
                    label: 'Diesel',
                    price: station['dieselPrice'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceTile(
                    label: 'Petrol',
                    price: station['petrolPrice'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigating to ${station['name']}...')),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Station selected!'),
                          backgroundColor: AppColors.electricGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricGreen,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    color: AppColors.navy,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              station['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          if (station['verified'])
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: AppColors.electricGreen,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.navigation, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${station['distance']} km',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${station['rating']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: station['open']
                        ? AppColors.electricGreen.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    station['open'] ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: station['open'] ? AppColors.electricGreen : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Diesel: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          'UGX ${station['dieselPrice']}/L',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Petrol: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          'UGX ${station['petrolPrice']}/L',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final int price;

  const _PriceTile({
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UGX $price',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const Text(
            'per liter',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
