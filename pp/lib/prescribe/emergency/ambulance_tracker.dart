import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pharmapulse/prescribe/emergency/emergency_home_page.dart';

class AmbulanceTrackingPage extends StatefulWidget {
  final LatLng userLocation;
  final Hospital? hospital; // Hospital is now optional

  const AmbulanceTrackingPage({
    super.key,
    required this.userLocation,
    this.hospital,
  });

  @override
  State<AmbulanceTrackingPage> createState() => _AmbulanceTrackingPageState();
}

class _AmbulanceTrackingPageState extends State<AmbulanceTrackingPage> {
  GoogleMapController? _mapController;
  late LatLng _ambulanceLocation;
  Timer? _timer;
  String _etaMessage = 'Calculating ETA...';

  @override
  void initState() {
    super.initState();
    _ambulanceLocation = LatLng(
      widget.userLocation.latitude + 0.02,
      widget.userLocation.longitude + 0.02,
    );
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    int etaMinutes = 5;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;

      final distance =
          (_ambulanceLocation.latitude - widget.userLocation.latitude).abs() +
          (_ambulanceLocation.longitude - widget.userLocation.longitude).abs();

      if (distance < 0.001) {
        timer.cancel();
        setState(() {
          _etaMessage = 'Ambulance has arrived at your location!';
        });
      } else {
        setState(() {
          // Simulate movement
          _ambulanceLocation = LatLng(
            _ambulanceLocation.latitude - 0.0005,
            _ambulanceLocation.longitude - 0.0005,
          );
          // Simulate ETA update
          if (timer.tick % 30 == 0 && etaMinutes > 1) {
            // every 60 seconds
            etaMinutes--;
          }
          _etaMessage = 'Ambulance arriving in ~ $etaMinutes mins';
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_ambulanceLocation),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Ambulance'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _ambulanceLocation,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('user'),
                position: widget.userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
              // Only show hospital marker if one was selected
              if (widget.hospital != null)
                Marker(
                  markerId: MarkerId(widget.hospital!.name),
                  position: widget.hospital!.location,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: InfoWindow(
                    title: 'Destination: ${widget.hospital!.name}',
                  ),
                ),
              Marker(
                markerId: const MarkerId('ambulance'),
                position: _ambulanceLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                infoWindow: const InfoWindow(title: 'Ambulance'),
              ),
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _etaMessage,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Driver: Ravi Kumar'),
                    subtitle: Text('Ambulance No: PB 11 AB 1234'),
                    trailing: Icon(Icons.call),
                  ),
                  // Conditionally show destination info
                  if (widget.hospital != null) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.local_hospital,
                        color: Colors.green,
                      ),
                      title: const Text(
                        'Your bed is booked at:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        widget.hospital!.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Request'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
