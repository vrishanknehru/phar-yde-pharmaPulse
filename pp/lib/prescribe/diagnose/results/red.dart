import 'package:flutter/material.dart';

class RedResultPage extends StatelessWidget {
  final Set<String> selectedSymptoms;
  final Map<String, dynamic>? apiResponse;

  const RedResultPage({
    super.key,
    required this.selectedSymptoms,
    this.apiResponse,
  });

  @override
  Widget build(BuildContext context) {
    final pred = apiResponse?["prediction"] ?? "Unknown";
    final advice = apiResponse?["advice"] ??
        "Seek medical help immediately. Condition may be severe.";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urgent Triage Result'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Icon(Icons.close, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text(
              "Prediction: $pred",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(advice, style: const TextStyle(fontSize: 16)),
            const Divider(height: 40),
            const Text(
              'Your Selected Symptoms:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: selectedSymptoms
                  .map((s) => Chip(label: Text(s)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
