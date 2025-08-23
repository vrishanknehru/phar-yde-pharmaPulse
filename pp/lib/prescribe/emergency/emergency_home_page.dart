import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pharmapulse/prescribe/emergency/ambulance_tracker.dart';
import 'package:url_launcher/url_launcher.dart';

// Data Model for a Hospital
class Hospital {
  final String name;
  final String address;
  final LatLng location;
  final int bedsAvailable;
  final int travelTimeMinutes;
  final double distanceKm;
  final double rating;
  final List<String> types;

  Hospital({
    required this.name,
    required this.address,
    required this.location,
    required this.bedsAvailable,
    required this.travelTimeMinutes,
    required this.distanceKm,
    this.rating = 4.0,
    this.types = const [],
  });
}

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  bool _isLoading = true;
  String _statusMessage = 'Getting your location...';
  LatLng? _userLocation;
  List<Hospital> _hospitals = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // Keywords to exclude pharmacy/chemist/drug stores
  final List<String> _excludedKeywords = const [
    'pharmacy',
    'chemist',
    'drug',
    'drugstore',
    'animal',
    'veterinary',
    'Medicos',
    'medicos',
    'medical store',
    'medicine shop',
    'apollo pharmacy',
    'medplus',
    'wellness forever',
    'netmeds',
    '1mg',
    'pharmeasy',
    'medical hall',
    'tablets',
    'medicines',
  ];

  // Types that indicate it's NOT a hospital
  final List<String> _excludedTypes = const [
    'pharmacy',
    'drugstore',
    'medicos',
    'store',
    'shopping_mall',
    'convenience_store',
    'supermarket',
  ];

  // Keywords that indicate it's actually a hospital
  final List<String> _hospitalKeywords = const [
    'hospital',
    'clinic',
    'medical center',
    'medical centre',
    'health center',
    'health centre',
    'emergency',
    'trauma',
    'nursing home',
    'healthcare',
    'multispeciality',
    'multi-speciality',
    'surgical',
    'maternity',
  ];

  @override
  void initState() {
    super.initState();
    _initializeEmergencyServices();
  }

  bool _isActualHospital(Map<String, dynamic> place) {
    final name = (place['name'] ?? '').toString().toLowerCase();
    final types = (place['types'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    // Exclude by name keywords
    for (final keyword in _excludedKeywords) {
      if (name.contains(keyword)) return false;
    }

    // Exclude by types
    for (final t in types) {
      if (_excludedTypes.contains(t)) return false;
    }

    // Include if has hospital-ish name OR hospital/health types
    final hasHospitalKeyword = _hospitalKeywords.any(
      (k) => name.contains(k.toLowerCase()),
    );
    final hasHospitalType = types.any(
      (t) => t.contains('hospital') || t.contains('health'),
    );

    return hasHospitalKeyword || hasHospitalType;
  }

  Future<void> _initializeEmergencyServices() async {
    try {
      final position = await _getUserLocation();
      _userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _statusMessage = 'Finding nearby hospitals...';
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('userLocation'),
            position: _userLocation!,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      });

      // Move map camera to user
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14),
      );

      await _fetchAndSortHospitals();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Could not get location.\nPlease ensure location permissions are enabled.\nError: $e';
      });
    }
  }

  /// Distance Matrix allows max 25 destinations per request when you have 1 origin.
  /// This batches destinations into chunks of 25 to avoid "max dimensions exceeded".
  Future<List<Map<String, dynamic>>> _fetchDistanceElementsInBatches(
    List<LatLng> destinations,
  ) async {
    const int maxPerRequest = 25; // <-- IMPORTANT
    final List<Map<String, dynamic>> allElements = [];

    for (int i = 0; i < destinations.length; i += maxPerRequest) {
      final chunk = destinations.sublist(
        i,
        i + maxPerRequest > destinations.length
            ? destinations.length
            : i + maxPerRequest,
      );

      final destParam = chunk
          .map((d) => '${d.latitude},${d.longitude}')
          .join('|');

      final distUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${_userLocation!.latitude},${_userLocation!.longitude}'
        '&destinations=$destParam'
        '&mode=driving'
        '&departure_time=now'
        '&key=$_apiKey',
      );

      final distResponse = await http.get(distUrl);

      if (distResponse.statusCode != 200) {
        throw Exception(
          'Distance Matrix HTTP ${distResponse.statusCode}: ${distResponse.reasonPhrase}',
        );
      }

      final distData = json.decode(distResponse.body);

      final status = (distData['status'] ?? '').toString();
      if (status != 'OK') {
        final msg = distData['error_message'] ?? 'Unknown error';
        throw Exception('Distance Matrix Error: $status - $msg');
      }

      final List<dynamic> elements = distData['rows'][0]['elements'];
      // Append maintaining order
      for (final e in elements) {
        allElements.add(Map<String, dynamic>.from(e as Map));
      }
    }

    return allElements;
  }

  Future<void> _fetchAndSortHospitals() async {
    if (_userLocation == null) return;

    // Nearby search: hospitals
    final hospitalUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_userLocation!.latitude},${_userLocation!.longitude}'
      '&radius=5000&type=hospital&key=$_apiKey',
    );

    try {
      final response = await http.get(hospitalUrl);

      if (response.statusCode != 200) {
        setState(() {
          _statusMessage =
              "HTTP Error ${response.statusCode}: ${response.reasonPhrase}";
        });
        return;
      }

      final data = json.decode(response.body);
      if ((data['status'] ?? '') != 'OK') {
        setState(() {
          _statusMessage =
              "API Error: ${data['status']} - ${data['error_message'] ?? ''}";
        });
        return;
      }

      List<dynamic> results = List<dynamic>.from(data['results'] ?? []);

      // Also search for type=health with hospital-related keywords to expand coverage
      final healthUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_userLocation!.latitude},${_userLocation!.longitude}'
        '&radius=5000&type=health&keyword=hospital|emergency|medical+center'
        '&key=$_apiKey',
      );

      final healthResponse = await http.get(healthUrl);
      if (healthResponse.statusCode == 200) {
        final healthData = json.decode(healthResponse.body);
        if ((healthData['status'] ?? '') == 'OK') {
          final List<dynamic> healthResults = List<dynamic>.from(
            healthData['results'] ?? [],
          );
          final existingIds = results
              .map((r) => r['place_id'].toString())
              .toSet();
          for (final place in healthResults) {
            if (!existingIds.contains(place['place_id'].toString())) {
              results.add(place);
            }
          }
        }
      }

      if (results.isEmpty) {
        setState(() {
          _statusMessage = "No hospitals found nearby.";
        });
        return;
      }

      // Filter to actual hospitals and collect destinations
      final List<Map<String, dynamic>> actualHospitals = [];
      final List<LatLng> hospitalLocations = [];

      for (final place in results) {
        if (_isActualHospital(place)) {
          final loc = place['geometry']?['location'];
          if (loc != null) {
            actualHospitals.add(Map<String, dynamic>.from(place));
            hospitalLocations.add(
              LatLng(
                (loc['lat'] as num).toDouble(),
                (loc['lng'] as num).toDouble(),
              ),
            );
          }
        }
      }

      if (actualHospitals.isEmpty) {
        setState(() {
          _statusMessage =
              "No actual hospitals found nearby (pharmacies excluded).";
        });
        return;
      }

      // ---- Distance Matrix (BATCHED) ----
      List<Map<String, dynamic>> elements = [];
      try {
        elements = await _fetchDistanceElementsInBatches(hospitalLocations);
      } on Exception catch (e) {
        setState(() {
          _statusMessage = e.toString();
        });
        return;
      }

      // Sanity: ensure we have same length
      final int count = min(actualHospitals.length, elements.length);

      final List<Hospital> foundHospitals = [];
      final random = Random();

      for (int i = 0; i < count; i++) {
        final place = actualHospitals[i];
        final elem = elements[i];

        if ((elem['status'] ?? '') != 'OK') continue;

        final int durationSeconds = elem['duration_in_traffic'] != null
            ? (elem['duration_in_traffic']['value'] as num).toInt()
            : (elem['duration']['value'] as num).toInt();

        final int durationMinutes = (durationSeconds / 60).round();
        final double distanceKm =
            ((elem['distance']?['value'] ?? 0) as num).toDouble() / 1000.0;

        final loc = place['geometry']['location'];
        foundHospitals.add(
          Hospital(
            name: place['name'] ?? 'Unknown Hospital',
            address: place['vicinity'] ?? 'Address not available',
            location: LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            ),
            bedsAvailable: random.nextInt(15),
            travelTimeMinutes: durationMinutes,
            distanceKm: distanceKm,
            rating: 3.5 + random.nextDouble() * 1.5,
            types: List<String>.from(place['types'] ?? []),
          ),
        );
      }

      // Sort by travel time
      foundHospitals.sort(
        (a, b) => a.travelTimeMinutes.compareTo(b.travelTimeMinutes),
      );

      setState(() {
        _hospitals = foundHospitals;
        // Clear old hospital markers but keep user location
        _markers.removeWhere((m) => m.markerId.value != 'userLocation');
        for (final hospital in _hospitals) {
          _markers.add(
            Marker(
              markerId: MarkerId(hospital.name),
              position: hospital.location,
              infoWindow: InfoWindow(
                title: hospital.name,
                snippet:
                    '${hospital.bedsAvailable} beds • ${hospital.distanceKm.toStringAsFixed(1)} km',
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Network/Error: $e";
      });
    }
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  void _bookBed(Hospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AmbulanceTrackingPage(userLocation: _userLocation!),
      ),
    );
  }

  void _callAmbulance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AmbulanceTrackingPage(userLocation: _userLocation!, hospital: null),
      ),
    );
  }

  void _retryHospitalSearch() {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Retrying hospital search...';
      _hospitals.clear();
    });
    _fetchAndSortHospitals().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _openDirections(Hospital hospital) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_userLocation!.latitude},${_userLocation!.longitude}'
      '&destination=${hospital.location.latitude},${hospital.location.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_userLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initializeEmergencyServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: _userLocation!,
            zoom: 14,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _hospitals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _retryHospitalSearch,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        const Icon(Icons.drag_handle, color: Colors.grey),
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_hospital,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nearest Hospitals',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                    ),
                                    Text(
                                      'Sorted by travel time (real-time)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.blue.shade600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_hospitals.length} Found',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _hospitals.length,
                            itemBuilder: (context, index) {
                              return _HospitalInfoCard(
                                hospital: _hospitals[index],
                                onBookBed: () => _bookBed(_hospitals[index]),
                                onDirections: () =>
                                    _openDirections(_hospitals[index]),
                                isFirst: index == 0,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: _userLocation != null
          ? FloatingActionButton.extended(
              onPressed: _callAmbulance,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency, size: 24),
              label: const Text('SOS Call'),
            )
          : null,
    );
  }
}

class _HospitalInfoCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onBookBed;
  final VoidCallback onDirections;
  final bool isFirst;

  const _HospitalInfoCard({
    required this.hospital,
    required this.onBookBed,
    required this.onDirections,
    this.isFirst = false,
  });

  Widget _buildRatingStars(double rating) {
    final List<Widget> stars = [];
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 16));
    }
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 16));
    }
    for (int i = stars.length; i < 5; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 16));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBeds = hospital.bedsAvailable > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFirst
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        border: Border.all(
          color: isFirst ? Colors.green.shade300 : Colors.grey.shade300,
          width: isFirst ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isFirst)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FASTEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isFirst) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hospital.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isFirst
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDirections,
                  tooltip: 'Get Directions',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hospital.address,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRatingStars(hospital.rating),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${hospital.travelTimeMinutes} mins • ${hospital.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasBeds
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.bed,
                          color: hasBeds
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasBeds
                              ? '${hospital.bedsAvailable} Beds Available'
                              : 'No Beds Available',
                          style: TextStyle(
                            color: hasBeds
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasBeds ? onBookBed : null,
                      icon: const Icon(Icons.book_online),
                      label: Text(
                        hasBeds ? 'Book Emergency Bed' : 'Unavailable',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasBeds ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
