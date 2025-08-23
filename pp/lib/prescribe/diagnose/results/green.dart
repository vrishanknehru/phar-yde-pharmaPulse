import 'package:flutter/material.dart';

class GreenResultPage extends StatelessWidget {
  final Set<String> selectedSymptoms;

  const GreenResultPage({super.key, required this.selectedSymptoms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Category: Green (Low Severity)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your symptoms, self-care is likely sufficient. Over-the-counter options may be available.',
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
              children: selectedSymptoms
                  .map((symptom) => Chip(label: Text(symptom)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}