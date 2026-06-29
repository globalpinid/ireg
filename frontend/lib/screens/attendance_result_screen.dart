import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AttendanceResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const AttendanceResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final totalDetected = result['total_detected'] ?? 0;
    final totalMatched = result['total_matched'] ?? 0;
    final matchedStudents = _matchedStudents();
    final unmatchedCount = result['unmatched_count'] ?? 0;
    final annotatedImage = _annotatedImageBytes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Result'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildCard('Detected', '$totalDetected', Colors.blue),
                const SizedBox(width: 12),
                _buildCard('Matched', '$totalMatched', Colors.green),
                const SizedBox(width: 12),
                _buildCard('Unknown', '$unmatchedCount', Colors.orange),
              ],
            ),
            if (annotatedImage != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showAnnotatedPreview(context, annotatedImage),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    annotatedImage,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(Colors.green, 'Matched'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.red, 'Unmatched'),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const Text('Present Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Belt', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 84, child: Text('Photo', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: matchedStudents.isEmpty
                  ? const Center(child: Text('No students matched', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: matchedStudents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) => _studentRow(context, matchedStudents[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _matchedStudents() {
    final raw = result['matched_students'];
    if (raw is! List) return [];
    return raw.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      return {'name': item.toString(), 'belt_color': '', 'photo_url': null};
    }).toList();
  }

  Uint8List? _annotatedImageBytes() {
    final annotatedImage = result['annotated_image'];
    if (annotatedImage is! String || annotatedImage.isEmpty) return null;
    return base64Decode(annotatedImage);
  }

  Widget _studentRow(BuildContext context, Map<String, dynamic> student) {
    final photoUrl = student['photo_url'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(student['name'] ?? '', style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Text((student['belt_color'] ?? '').toString().toUpperCase()),
          ),
          SizedBox(
            width: 84,
            height: 84,
            child: InkWell(
              onTap: photoUrl == null || photoUrl.isEmpty ? null : () => _showPhotoPreview(context, student),
              borderRadius: BorderRadius.circular(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _photoImage(photoUrl, iconSize: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoImage(String? photoUrl, {double iconSize = 28}) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.person, color: Colors.grey, size: iconSize),
      );
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image, color: Colors.grey, size: iconSize),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, Map<String, dynamic> student) {
    final photoUrl = student['photo_url'] as String?;
    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(photoUrl, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student['name'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnotatedPreview(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(
                minScale: 0.7,
                maxScale: 4,
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
