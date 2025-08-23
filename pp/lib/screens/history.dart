import 'package:flutter/material.dart';
import 'package:pharmapulse/screens/home_page.dart';
import 'package:pharmapulse/services/prescription_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();

  @override
  void initState() {
    super.initState();
    // Listen for changes from the service
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
    final prescriptions = _prescriptionService.prescriptions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        // --- ADD THIS LEADING WIDGET FOR A BACK BUTTON ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(username: 'yourUsername'),
              ),
            );
          },
        ),
      ),
      body: ListView.builder(
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return _PrescriptionCard(prescription: prescription);
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (prescription.status) {
      case PrescriptionStatus.Approved:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case PrescriptionStatus.Rejected:
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusIcon = Icons.hourglass_top_rounded;
        statusColor = Colors.orange;
        statusText = 'Pending Approval';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.grey.shade700, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Prescription ID: ${prescription.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (prescription.status == PrescriptionStatus.Approved) ...[
              const Text(
                'Medicines Added by Chemist:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...prescription.medicines.map(
                (med) => ListTile(
                  title: Text(med.name),
                  trailing: Text('₹${med.price.toStringAsFixed(2)}'),
                  dense: true,
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Cost: ₹${prescription.totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Use CartManager to add these items to cart
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                ],
              ),
            ] else
              Text(
                'Your prescription is awaiting review by a pharmacist.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
          ],
        ),
      ),
    );
  }
}
