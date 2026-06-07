import 'package:flutter/material.dart';

class AttendanceResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const AttendanceResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final totalDetected = result['total_detected'] ?? 0;
    final totalMatched = result['total_matched'] ?? 0;
    final matchedStudents = List<String>.from(result['matched_students'] ?? []);
    final unmatchedCount = result['unmatched_count'] ?? 0;

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
            // Summary cards
            Row(
              children: [
                _buildCard('Detected', '$totalDetected', Colors.blue),
                const SizedBox(width: 12),
                _buildCard('Matched', '$totalMatched', Colors.green),
                const SizedBox(width: 12),
                _buildCard('Unknown', '$unmatchedCount', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Present Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Student list
            Expanded(
              child: matchedStudents.isEmpty
                  ? const Center(child: Text('No students matched', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: matchedStudents.length,
                      itemBuilder: (_, index) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(matchedStudents[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
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
