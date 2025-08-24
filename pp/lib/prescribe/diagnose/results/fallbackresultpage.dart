import 'dart:convert';
import 'package:flutter/material.dart';

class FallbackResultPage extends StatelessWidget {
  final Set<String> selectedSymptoms;
  final Map<String, dynamic>? rawResponse;
  final String? errorFromApi;

  const FallbackResultPage({
    super.key,
    required this.selectedSymptoms,
    this.rawResponse,
    this.errorFromApi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Icon(Icons.info, color: Colors.grey, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Category: Unknown',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorFromApi ?? "Could not determine your condition. Try again.",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
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
            if (rawResponse != null) ...[
              const Divider(),
              const Text("API Debug Output:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                const JsonEncoder.withIndent('  ').convert(rawResponse),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              )
            ]
          ],
        ),
      ),
    );
  }
}
