import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharmapulse/prescribe/diagnose/results/red.dart';

class MedicalHistoryPage extends StatefulWidget {
  final Set<String> selectedSymptoms;
  const MedicalHistoryPage({super.key, required this.selectedSymptoms});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  int? _patientAge;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  String _baseUrl() {
    // Android emulator -> your PC
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    // iOS simulator / desktop
    return "http://127.0.0.1:8000";
    // Physical device (Wi-Fi):
    // return "http://<YOUR_PC_LAN_IP>:8000";
  }

  Future<Map<String, dynamic>> _predictOnServer({
    required int age,
    required Set<String> symptoms,
  }) async {
    final url = Uri.parse("${_baseUrl()}/predict");
    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"age": age, "symptoms": symptoms.toList()}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception("API ${res.statusCode}: ${res.body}");
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _submitMedicalHistory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _patientAge = int.parse(_ageController.text);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? api;
    String? apiError;
    try {
      api = await _predictOnServer(
        age: _patientAge!,
        symptoms: widget.selectedSymptoms,
      );
    } catch (e) {
      apiError = e.toString();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }

    bool isRed = false;
    double? risk;

    if (api != null) {
      if (api["risk"] != null) {
        risk = (api["risk"] as num).toDouble();
        isRed = risk >= 0.60; // adjust with your model’s cutoff
      } else {
        final pred = api["prediction"];
        if (pred is num) isRed = pred >= 1;
        if (pred is String) {
          isRed = pred.toLowerCase().contains("red");
        }
      }
    }

    // Fallback rule
    if (!isRed && widget.selectedSymptoms.length >= 4) {
      isRed = true;
    }

    if (!mounted) return;

    if (isRed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RedResultPage(selectedSymptoms: widget.selectedSymptoms),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YellowResultPage(
            selectedSymptoms: widget.selectedSymptoms,
            modelLabel: api?["prediction"]?.toString(),
            risk: risk,
            rawResponse: api,
            errorFromApi: apiError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please enter your details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'e.g., 35',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n < 0 || n > 120) {
                    return 'Please enter a valid age (0–120)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitMedicalHistory,
                icon: const Icon(Icons.save),
                label: const Text('Save & Diagnose'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Yellow page shows model output (unchanged except small polish) ---
class YellowResultPage extends StatelessWidget {
  final Set<String> selectedSymptoms;
  final String? modelLabel;
  final double? risk;
  final Map<String, dynamic>? rawResponse;
  final String? errorFromApi;

  const YellowResultPage({
    super.key,
    required this.selectedSymptoms,
    this.modelLabel,
    this.risk,
    this.rawResponse,
    this.errorFromApi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Icon(Icons.warning_rounded, color: Colors.yellow[800], size: 80),
            const SizedBox(height: 16),
            const Text(
              'Category: Yellow (Moderate Severity)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your inputs, consider consulting a doctor (non-emergency).',
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            if (errorFromApi != null) ...[
              Text(
                'Model API Error',
                style: theme.textTheme.titleMedium!.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 6),
              Text(errorFromApi!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Model Output',
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (modelLabel != null) Text('Prediction: $modelLabel'),
              if (risk != null)
                Text('Risk: ${(risk! * 100).toStringAsFixed(1)}%'),
              if (rawResponse != null) ...[
                const SizedBox(height: 8),
                Text(
                  const JsonEncoder.withIndent('  ').convert(rawResponse),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
