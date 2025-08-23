import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class UploadPrescriptionPage extends StatefulWidget {
  const UploadPrescriptionPage({super.key});

  @override
  State<UploadPrescriptionPage> createState() => _UploadPrescriptionPageState();
}

class _UploadPrescriptionPageState extends State<UploadPrescriptionPage> {
  File? _selectedFile;
  String _fileType = '';

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileType = 'image';
      });
    }
  }

  // Function to take a picture with the camera
  Future<void> _takePictureWithCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileType = 'image';
      });
    }
  }

  // Function to pick a PDF file
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'pdf';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: _selectedFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No file selected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : _fileType == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_selectedFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 80,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Upload Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onPressed: _pickImageFromGallery,
                ),
                _buildOptionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onPressed: _takePictureWithCamera,
                ),
                _buildOptionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onPressed: _pickPdf,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Continue Button
            ElevatedButton(
              onPressed: _selectedFile == null
                  ? null // Button is disabled if no file is selected
                  : () {
                      // TODO: Add logic to upload the file to your backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Uploading prescription...'),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 40),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
