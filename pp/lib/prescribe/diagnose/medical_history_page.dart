import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharmapulse/prescribe/diagnose/results/green.dart';
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
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://127.0.0.1:8000";
    // For physical device (Wi-Fi):
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

    if (!mounted) return;

    if (api != null) {
      final category = (api["category"] ?? "unknown").toString().toLowerCase();

      if (category == "red") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RedResultPage(
              selectedSymptoms: widget.selectedSymptoms,
              apiResponse: api,
            ),
          ),
        );
        return;
      } else if (category == "green") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GreenResultPage(
              selectedSymptoms: widget.selectedSymptoms,
              apiResponse: api,
            ),
          ),
        );
        return;
      }
    }

    // fallback → treat as red (safety first)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RedResultPage(
          selectedSymptoms: widget.selectedSymptoms,
          apiResponse: api,
        ),
      ),
    );
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
