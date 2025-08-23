import 'package:flutter/material.dart';
import 'package:pharmapulse/prescribe/diagnose/prescribe_page.dart';
import 'package:pharmapulse/prescribe/upload_pres/upload_prescription.dart';

class ChoicePage extends StatelessWidget {
  const ChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Prescription'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 
              // --- Button to get a new prescription ---
              ElevatedButton.icon(
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Get a Prescription'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: Colors.teal, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Navigate to the PrescribedPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrescribePage()),
                  );
                },
              ),
              const SizedBox(height: 25), // Spacer between buttons
              // 
              // --- Button to upload an existing prescription ---
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload Prescription'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: Colors.blueGrey, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 15),
                   textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Navigate to the UploadPrescriptionPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadPrescriptionPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
