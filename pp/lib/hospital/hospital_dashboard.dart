import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pharmapulse/screens/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// You will need to create these files if they don't exist
// import 'package:pharmapulse/models/hospital_request.dart';
// import 'package:pharmapulse/screens/patient_verification.dart';
// import 'package:pharmapulse/screens/login_page.dart';

// Data model for a hospital request
class HospitalRequest {
  final String patientName;
  final LatLng patientLocation;
  final String patientSymptoms;
  final DateTime requestTime;
  final int patientAge;
  String status;

  HospitalRequest({
    required this.patientName,
    required this.patientLocation,
    required this.patientSymptoms,
    required this.requestTime,
    required this.patientAge,
    this.status = 'Confirmed',
  });
}

// Page to verify patient arrival
class PatientVerificationPage extends StatefulWidget {
  final HospitalRequest request;

  const PatientVerificationPage({super.key, required this.request});

  @override
  State<PatientVerificationPage> createState() => _PatientVerificationPageState();
}

class _PatientVerificationPageState extends State<PatientVerificationPage> {
  String _currentStatus = 'Arrived';

  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    widget.request.status = newStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify ${widget.request.patientName}'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${widget.request.patientName} (${widget.request.patientAge})',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Arrival Time: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 40),
            Text(
              'Current Status: $_currentStatus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _currentStatus == 'Discharged' ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _updateStatus('Admitted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Admitted'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _updateStatus('Discharged'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Discharged'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// Hospital Dashboard page
class HospitalDashboardPage extends StatefulWidget {
  const HospitalDashboardPage({super.key});

  @override
  State<HospitalDashboardPage> createState() => _HospitalDashboardPageState();
}

class _HospitalDashboardPageState extends State<HospitalDashboardPage> {
  final List<HospitalRequest> _requests = [];
  LatLng? _hospitalLocation;

  @override
  void initState() {
    super.initState();
    _hospitalLocation = const LatLng(28.7041, 77.1025); // Example: Delhi

    _requests.add(HospitalRequest(
      patientName: 'Jane Doe',
      patientAge: 32,
      patientLocation: const LatLng(28.6542, 77.2373), // A nearby location
      patientSymptoms: 'Fever, Body Ache',
      requestTime: DateTime.now().subtract(const Duration(minutes: 5)),
      status: 'Confirmed',
    ));
  }

  void _navigateToPatient(HospitalRequest request) async {
    final origin = '${_hospitalLocation!.latitude},${_hospitalLocation!.longitude}';
    final destination = '${request.patientLocation.latitude},${request.patientLocation.longitude}';

    final url = Uri.parse(
      'https://www.google.com/maps/dir//Prince+Aly+Khan+Hospital,+XRCP%2BF92,+Prince+Ally+Khan+Hospital+Road,+Tara+Bagh,+Mazgaon,+Mumbai,+Maharashtra,+India/data=!4m9!4m8!1m0!1m5!1m1!19sChIJ5R11YkbO5zsRguUVDg6Ax44!2m2!1d72.8358811!2d18.971149999999998!3e09',
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
        title: const Text('Hospital Dashboard'),
        backgroundColor: Colors.blue.shade800,
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
      body: _requests.isEmpty
          ? const Center(
              child: Text(
                'No incoming bed requests.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient: ${request.patientName} (${request.patientAge})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${request.status}'),
                        Text(
                          'Requested: ${DateFormat.yMMMd().add_jm().format(request.requestTime)}',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Symptoms: ${request.patientSymptoms}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _navigateToPatient(request);
                                },
                                icon: const Icon(Icons.directions_car),
                                label: const Text('Navigate to Patient'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PatientVerificationPage(
                                        request: request,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Verify Arrival'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
