import 'dart:io';
import 'package:flutter/material.dart';

// --- Data Models ---

enum PrescriptionStatus { Pending, Approved, Rejected }

class MedicineItem {
  final String name;
  final double price;
  MedicineItem({required this.name, required this.price});
}

class Prescription {
  final String id;
  final File? prescriptionFile; // For simplicity, we'll use a placeholder
  PrescriptionStatus status;
  List<MedicineItem> medicines;
  double totalCost;

  Prescription({
    required this.id,
    this.prescriptionFile,
    this.status = PrescriptionStatus.Pending,
    this.medicines = const [],
    this.totalCost = 0.0,
  });
}

// --- The Shared Service (Singleton) ---

class PrescriptionService extends ChangeNotifier {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final List<Prescription> _prescriptions = [
    // Add some mock data to start with
    Prescription(id: '1', status: PrescriptionStatus.Pending),
    Prescription(
      id: '2',
      status: PrescriptionStatus.Approved,
      medicines: [
        MedicineItem(name: 'Crocin Advance', price: 30),
        MedicineItem(name: 'Dettol 200ml', price: 95),
      ],
      totalCost: 125.0,
    ),
  ];

  List<Prescription> get prescriptions => _prescriptions;

  void addPrescription(File file) {
    final newId = (_prescriptions.length + 1).toString();
    _prescriptions.add(Prescription(id: newId, prescriptionFile: file));
    notifyListeners();
  }

  void approvePrescription(String id, List<MedicineItem> medicines) {
    final prescription = _prescriptions.firstWhere((p) => p.id == id);
    prescription.status = PrescriptionStatus.Approved;
    prescription.medicines = medicines;
    prescription.totalCost = medicines.fold(0.0, (sum, item) => sum + item.price);
    notifyListeners();
  }
}