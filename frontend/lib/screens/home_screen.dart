import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'attendance_result_screen.dart';
import 'enroll_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  bool _isProcessing = false;
  int _sessionNumber = 1;
  final List<_SessionOption> _sessions = const [
    _SessionOption(1, '5-AM', true),
    _SessionOption(2, '6-AM', true),
    _SessionOption(3, '7-AM', true),
    _SessionOption(4, '4-PM', false),
    _SessionOption(5, '5-PM', false),
    _SessionOption(6, '6-PM', false),
    _SessionOption(7, '7-PM', false),
  ];

  Future<void> _takeGroupPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await photo.readAsBytes();
      final result = await _api.markAttendance(
        photoBytes: bytes,
        fileName: photo.name,
        sessionNumber: _sessionNumber,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AttendanceResultScreen(result: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iReg'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollScreen())),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Karate Academy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap the camera to mark attendance', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 48),
            // Session number selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Session: ', style: TextStyle(fontSize: 16)),
                DropdownButton<int>(
                  value: _sessionNumber,
                  selectedItemBuilder: (_) => _sessions
                      .map(
                        (session) => Text(
                          session.label,
                          style: TextStyle(
                            color: session.isMorning ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                      .toList(),
                  items: _sessions
                      .map(
                        (session) => DropdownMenuItem(
                          value: session.value,
                          child: Text(
                            session.label,
                            style: TextStyle(
                              color: session.isMorning ? Colors.blue : Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _sessionNumber = v!),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Camera button
            GestureDetector(
              onTap: _isProcessing ? null : _takeGroupPhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isProcessing ? Colors.grey : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera_alt, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing) const Text('Processing faces...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SessionOption {
  final int value;
  final String label;
  final bool isMorning;

  const _SessionOption(this.value, this.label, this.isMorning);
}
