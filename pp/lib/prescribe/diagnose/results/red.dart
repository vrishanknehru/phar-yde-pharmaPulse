import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Data model for a medical place
class MedicalPlace {
  final String name;
  final String address;
  final String? phoneNumber;
  final double? rating;

  MedicalPlace({
    required this.name,
    required this.address,
    this.phoneNumber,
    this.rating,
  });
}

class RedResultPage extends StatefulWidget {
  final Set<String> selectedSymptoms;

  const RedResultPage({super.key, required this.selectedSymptoms});

  @override
  State<RedResultPage> createState() => _RedResultPageState();
}

class _RedResultPageState extends State<RedResultPage> {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
  List<MedicalPlace> _nearbyPlaces = [];
  bool _isLoading = true;
  String _statusMessage = 'Fetching nearby medical facilities...';

  @override
  void initState() {
    super.initState();
    _fetchNearbyMedicalFacilities();
  }

  Future<void> _fetchNearbyMedicalFacilities() async {
    try {
      final position = await _getUserLocation();
      final userLocation = '${position.latitude},${position.longitude}';

      setState(() {
        _statusMessage = 'Searching for nearby doctors and clinics...';
      });

      // Search for doctors and clinics
      final doctorsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$userLocation'
        '&radius=5000'
        '&type=doctor|hospital|clinic'
        '&key=$_apiKey',
      );

      final response = await http.get(doctorsUrl);
      if (response.statusCode != 200) {
        throw Exception('Failed to load places: ${response.reasonPhrase}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        throw Exception('API Error: ${data['error_message']}');
      }

      final List<MedicalPlace> places = [];
      for (var place in data['results']) {
        final placeId = place['place_id'];
        final placeName = place['name'];
        final placeAddress = place['vicinity'];
        final placeRating = place['rating']?.toDouble();

        // Fetch phone number using Place Details API
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=formatted_phone_number'
          '&key=$_apiKey',
        );

        final detailsResponse = await http.get(detailsUrl);
        String? phoneNumber;
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          phoneNumber = detailsData['result']['formatted_phone_number'];
        }

        places.add(
          MedicalPlace(
            name: placeName,
            address: placeAddress,
            phoneNumber: phoneNumber,
            rating: placeRating,
          ),
        );
      }

      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
        if (places.isEmpty) {
          _statusMessage = "No nearby medical facilities found.";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  Future<void> _openGoogleSearch(MedicalPlace place) async {
    final query = Uri.encodeComponent('${place.name} ${place.address}');
    final Uri launchUri = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open search page.')),
        );
      }
    }
  }

  Widget _buildPlaceCard(MedicalPlace place) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: () => _openGoogleSearch(place),
        leading: const Icon(Icons.local_hospital, color: Colors.redAccent),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.address),
            if (place.rating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(place.rating.toString()),
                ],
              ),
            if (place.phoneNumber != null)
              Text(
                place.phoneNumber!,
                style: const TextStyle(color: Colors.blue),
              ),
          ],
        ),
        trailing: place.phoneNumber != null
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(place.phoneNumber),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.dangerous, color: Colors.redAccent, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Category: Red (High Severity)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your symptoms suggest you should seek medical advice promptly. Please consider connecting with a doctor immediately.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Divider(height: 40),
              const Text(
                'Your Selected Symptoms:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.selectedSymptoms
                    .map((symptom) => Chip(label: Text(symptom)))
                    .toList(),
              ),
              const Divider(height: 40),
              const Text(
                'Nearby Doctors & Clinics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(_statusMessage),
                    ],
                  ),
                )
              else if (_nearbyPlaces.isEmpty)
                Center(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                Column(
                  children: _nearbyPlaces
                      .map((place) => _buildPlaceCard(place))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
