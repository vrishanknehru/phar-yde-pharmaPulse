import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:pharmapulse/screens/login_page.dart'; // Import the main login page

// Data model for an emergency request
class EmergencyRequest {
  final String requestId;
  final LatLng userLocation;
  final String userName;
  final DateTime timestamp;
  bool isAccepted;

  EmergencyRequest({
    required this.requestId,
    required this.userLocation,
    required this.userName,
    required this.timestamp,
    this.isAccepted = false,
  });
}

// Data model for a hospital
class Hospital {
  final String name;
  final String address;
  final LatLng location;

  Hospital({required this.name, required this.address, required this.location});
}

class AmbulanceDriverDashboard extends StatefulWidget {
  const AmbulanceDriverDashboard({super.key});

  @override
  State<AmbulanceDriverDashboard> createState() =>
      _AmbulanceDriverDashboardState();
}

class _AmbulanceDriverDashboardState extends State<AmbulanceDriverDashboard> {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  bool _isLoading = true;
  String _statusMessage = 'Fetching your current location...';
  LatLng? _driverLocation;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  final List<EmergencyRequest> _incomingRequests = [];
  EmergencyRequest? _acceptedRequest;
  Hospital? _nearestHospital;
  bool _isPatientPickedUp = false;
  bool _isPatientDroppedOff = false;

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

  final List<String> _excludedTypes = const [
    'pharmacy',
    'drugstore',
    'medicos',
    'store',
    'shopping_mall',
    'convenience_store',
    'supermarket',
  ];

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
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      final position = await _getDriverLocation();
      _driverLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Ready to receive requests.';
        _markers.add(
          Marker(
            markerId: const MarkerId('driverLocation'),
            position: _driverLocation!,
            infoWindow: const InfoWindow(title: 'Your Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 14),
      );

      _simulateNewRequest();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<Position> _getDriverLocation() async {
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
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _simulateNewRequest() {
    Future.delayed(const Duration(seconds: 5), () {
      final newRequest = EmergencyRequest(
        requestId: 'req_001',
        userLocation: LatLng(
          _driverLocation!.latitude + 0.005,
          _driverLocation!.longitude + 0.005,
        ),
        userName: 'User A',
        timestamp: DateTime.now(),
      );
      setState(() {
        _incomingRequests.add(newRequest);
      });
    });
  }

  void _acceptRequest(EmergencyRequest request) async {
    _markers.removeWhere((m) => m.markerId.value != 'driverLocation');
    _markers.add(
      Marker(
        markerId: MarkerId(request.requestId),
        position: request.userLocation,
        infoWindow: InfoWindow(title: 'Request from ${request.userName}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    setState(() {
      _acceptedRequest = request;
      _incomingRequests.clear();
      _statusMessage = 'Request accepted. Driving to ${request.userName}...';
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _driverLocation!.latitude < request.userLocation.latitude
                ? _driverLocation!.latitude
                : request.userLocation.latitude,
            _driverLocation!.longitude < request.userLocation.longitude
                ? _driverLocation!.longitude
                : request.userLocation.longitude,
          ),
          northeast: LatLng(
            _driverLocation!.latitude > request.userLocation.latitude
                ? _driverLocation!.latitude
                : request.userLocation.latitude,
            _driverLocation!.longitude > request.userLocation.longitude
                ? _driverLocation!.longitude
                : request.userLocation.longitude,
          ),
        ),
        100,
      ),
    );
  }

  void _rejectRequest(EmergencyRequest request) {
    setState(() {
      _incomingRequests.remove(request);
      _statusMessage = 'Request rejected. Waiting for new requests.';
    });
  }

  Future<void> _onPatientPickedUp() async {
    setState(() {
      _isLoading = true;
      _isPatientPickedUp = true;
      _statusMessage = 'Searching for nearest hospital...';
    });

    try {
      final position = await _getDriverLocation();
      _driverLocation = LatLng(position.latitude, position.longitude);

      final hospitals = await _findNearestHospital(_driverLocation!);

      if (hospitals.isNotEmpty) {
        setState(() {
          _nearestHospital = hospitals.first;
          _statusMessage = 'Nearest hospital found: ${_nearestHospital!.name}';

          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('driverLocation'),
              position: _driverLocation!,
              infoWindow: const InfoWindow(title: 'You are here'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('nearestHospital'),
              position: _nearestHospital!.location,
              infoWindow: InfoWindow(title: _nearestHospital!.name),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                _driverLocation!.latitude < _nearestHospital!.location.latitude
                    ? _driverLocation!.latitude
                    : _nearestHospital!.location.latitude,
                _driverLocation!.longitude <
                        _nearestHospital!.location.longitude
                    ? _driverLocation!.longitude
                    : _nearestHospital!.location.longitude,
              ),
              northeast: LatLng(
                _driverLocation!.latitude > _nearestHospital!.location.latitude
                    ? _driverLocation!.latitude
                    : _nearestHospital!.location.latitude,
                _driverLocation!.longitude >
                        _nearestHospital!.location.longitude
                    ? _driverLocation!.longitude
                    : _nearestHospital!.location.longitude,
              ),
            ),
            100,
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'No nearby hospitals found. Please search manually.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error searching for hospitals: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPatientDroppedOff() {
    setState(() {
      _isPatientDroppedOff = true;
      _isPatientPickedUp = false;
      _acceptedRequest = null;
      _nearestHospital = null;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('driverLocation'),
          position: _driverLocation!,
          infoWindow: const InfoWindow(title: 'Your Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _statusMessage =
          'Patient dropped off successfully. Ready for next request.';
    });
  }

  Future<List<Hospital>> _findNearestHospital(LatLng location) async {
    final hospitalUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=10000'
      '&type=hospital'
      '&key=$_apiKey',
    );

    final response = await http.get(hospitalUrl);
    if (response.statusCode != 200) {
      return [];
    }
    final data = json.decode(response.body);
    if (data['status'] != 'OK') {
      return [];
    }

    List<dynamic> results = data['results'] ?? [];
    List<Hospital> hospitals = [];
    for (var result in results) {
      final String name = result['name'];
      final List<dynamic> types = result['types'] ?? [];

      final bool isExcluded =
          _excludedKeywords.any(
            (keyword) => name.toLowerCase().contains(keyword),
          ) ||
          _excludedTypes.any((type) => types.contains(type));

      final bool isHospital = _hospitalKeywords.any(
        (keyword) => name.toLowerCase().contains(keyword),
      );

      if (!isExcluded || isHospital) {
        final loc = result['geometry']['location'];
        hospitals.add(
          Hospital(
            name: name,
            address: result['vicinity'],
            location: LatLng(loc['lat'], loc['lng']),
          ),
        );
      }
    }

    hospitals.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    return hospitals;
  }

  Future<void> _openDirections({
    required LatLng destination,
    String? origin,
  }) async {
    if (origin == null && _driverLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
      }
      return;
    }

    final destinationStr = '${destination.latitude},${destination.longitude}';
    final originStr =
        origin ?? '${_driverLocation!.latitude},${_driverLocation!.longitude}';

    final url = Uri.parse(
      'https://www.google.com/maps/dir//Prince+Aly+Khan+Hospital,+XRCP%2BF92,+Prince+Ally+Khan+Hospital+Road,+Tara+Bagh,+Mazgaon,+Mumbai,+Maharashtra,+India/data=!4m9!4m8!1m0!1m5!1m1!19sChIJ5R11YkbO5zsRguUVDg6Ax44!2m2!1d72.8358811!2d18.971149999999998!3e05',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Dashboard'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          else if (_isPatientDroppedOff)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildFinalStatusCard(),
            )
          else if (_isPatientPickedUp)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildHospitalDirectionsCard(),
            )
          else if (_acceptedRequest != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildAcceptedCard(_acceptedRequest!),
            )
          else if (_incomingRequests.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildRequestCard(_incomingRequests.first),
            )
          else
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(EmergencyRequest request) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INCOMING EMERGENCY REQUEST',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_pin_circle, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'User: ${request.userName}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Time: ${request.timestamp.minute}:${request.timestamp.second} mins ago',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildAcceptedCard(EmergencyRequest request) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REQUEST ACCEPTED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_pin, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Heading to ${request.userName}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openDirections(destination: request.userLocation),
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation to Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onPatientPickedUp,
                icon: const Icon(Icons.person_add),
                label: const Text('Patient Picked Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
    );
  }

  Widget _buildHospitalDirectionsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATIENT ONBOARD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            if (_nearestHospital != null) ...[
              const Text(
                'Destination: Nearest Hospital',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nearestHospital!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openDirections(destination: _nearestHospital!.location),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate to Hospital'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onPatientDroppedOff,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Patient Dropped Off'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else
              Center(child: Text(_statusMessage)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalStatusCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isPatientDroppedOff = false;
                    _isLoading = true;
                  });
                  _initializeDashboard();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Start New Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
    );
  }
}
