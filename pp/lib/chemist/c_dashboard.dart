import 'package:flutter/material.dart';
import 'package:pharmapulse/screens/login_page.dart'; // Import the LoginPage
import 'package:pharmapulse/services/prescription_service.dart';

class ChemistDashboardPage extends StatefulWidget {
  const ChemistDashboardPage({super.key});

  @override
  State<ChemistDashboardPage> createState() => _ChemistDashboardPageState();
}

class _ChemistDashboardPageState extends State<ChemistDashboardPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();

  @override
  void initState() {
    super.initState();
    _prescriptionService.addListener(_onPrescriptionUpdated);
  }

  @override
  void dispose() {
    _prescriptionService.removeListener(_onPrescriptionUpdated);
    super.dispose();
  }

  void _onPrescriptionUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingPrescriptions = _prescriptionService.prescriptions
        .where((p) => p.status == PrescriptionStatus.Pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chemist Dashboard"),
        // --- ADD LOGOUT BUTTON HERE ---
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () {
            // Navigate back to the login page and remove all other screens
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: pendingPrescriptions.isEmpty
          ? const Center(child: Text("No pending prescriptions."))
          : ListView.builder(
              itemCount: pendingPrescriptions.length,
              itemBuilder: (context, index) {
                final prescription = pendingPrescriptions[index];
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text('Prescription ID: ${prescription.id}'),
                  subtitle: const Text('Status: Pending'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showApprovalDialog(prescription),
                );
              },
            ),
    );
  }

  void _showApprovalDialog(Prescription prescription) {
    final mockMedicines = [
      MedicineItem(name: 'Paracetamol 500mg', price: 30.00),
      MedicineItem(name: 'Vitamin C Tablets', price: 150.00),
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Prescription #${prescription.id}'),
        content: const Text('Add the following medicines and send the quote to the user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _prescriptionService.approvePrescription(prescription.id, mockMedicines);
              Navigator.pop(context);
            },
            child: const Text('Approve & Send'),
          ),
        ],
      ),
    );
  }
}