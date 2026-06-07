import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EnrollScreen extends StatefulWidget {
  const EnrollScreen({super.key});

  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  final ApiService _api = ApiService();
  final _nameController = TextEditingController();
  String _beltColor = 'white';
  bool _isLoading = false;

  final List<String> _beltColors = ['white', 'yellow', 'orange', 'green', 'blue', 'brown', 'black'];

  Future<void> _enrollStudent() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter student name')),
      );
      return;
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await photo.readAsBytes();
      final result = await _api.enrollStudent(
        name: _nameController.text.trim(),
        beltColor: _beltColor,
        photoBytes: bytes,
        fileName: photo.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['name']} enrolled successfully!'), backgroundColor: Colors.green),
        );
        _nameController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Student'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _beltColor,
              decoration: const InputDecoration(
                labelText: 'Belt Color',
                border: OutlineInputBorder(),
              ),
              items: _beltColors.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _beltColor = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _enrollStudent,
              icon: const Icon(Icons.camera_alt),
              label: Text(_isLoading ? 'Processing...' : 'Take Photo & Enroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
