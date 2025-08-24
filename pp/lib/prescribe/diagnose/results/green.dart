import 'package:flutter/material.dart';

class GreenResultPage extends StatelessWidget {
  final Set<String> selectedSymptoms;
  final Map<String, dynamic>? apiResponse;

  const GreenResultPage({
    super.key,
    required this.selectedSymptoms,
    this.apiResponse,
  });

  @override
  Widget build(BuildContext context) {
    final pred = apiResponse?["prediction"] ?? "Unknown";
    final advice = apiResponse?["advice"] ??
        "Self-care and OTC medication may help manage your condition.";
    final meds = (apiResponse?["recommended_meds"] ?? []) as List;
    final dosage = apiResponse?["dosage"];
    final duration = apiResponse?["duration"];
    final safety = apiResponse?["safety_notes"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              "Prediction: $pred",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(advice, style: const TextStyle(fontSize: 16)),
            const Divider(height: 40),

            // OTC Medicines Section
            ExpansionTile(
              leading: const Icon(Icons.medical_services, color: Colors.green),
              title: const Text(
                "Recommended OTC Medicines",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: [
                if (meds.isNotEmpty)
                  ...List.generate(meds.length, (i) {
                    return ListTile(
                      leading: const Icon(Icons.check, color: Colors.green),
                      title: Text(meds[i].toString()),
                    );
                  }),
                if (dosage != null)
                  ListTile(
                    title: Text("Dosage: $dosage"),
                    leading: const Icon(Icons.schedule, color: Colors.teal),
                  ),
                if (duration != null)
                  ListTile(
                    title: Text("Duration: $duration"),
                    leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  ),
                if (safety != null)
                  ListTile(
                    title: Text("Safety: $safety"),
                    leading: const Icon(Icons.shield, color: Colors.teal),
                  ),
                if (meds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "No OTC meds found for this condition.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
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
          ],
        ),
      ),
    );
  }
}
