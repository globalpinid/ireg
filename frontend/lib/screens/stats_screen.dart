import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _dayStats;
  Map<String, dynamic>? _yesterdayStats;
  Map<String, dynamic>? _dateStats;
  List<dynamic>? _students;
  Map<String, dynamic>? _selectedDaySession;
  Map<String, dynamic>? _selectedYesterdaySession;
  Map<String, dynamic>? _selectedDateSession;
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _isDateLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getDayStats(),
        _api.getYesterdayStats(),
        _api.getStudents(),
      ]);
      setState(() {
        _dayStats = results[0] as Map<String, dynamic>;
        _yesterdayStats = results[1] as Map<String, dynamic>;
        _students = results[2] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _selectedDateSession = null;
      _isDateLoading = true;
    });

    try {
      final stats = await _api.getDayStats(date: _formatDate(picked));
      setState(() {
        _dateStats = stats;
        _isDateLoading = false;
      });
    } catch (e) {
      setState(() => _isDateLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading date: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Yesterday'),
            Tab(text: 'Date'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSessionTab(
                  stats: _dayStats,
                  selectedSession: _selectedDaySession,
                  onSessionSelected: (session) => setState(() => _selectedDaySession = session),
                  onBack: () => setState(() => _selectedDaySession = null),
                ),
                _buildSessionTab(
                  stats: _yesterdayStats,
                  selectedSession: _selectedYesterdaySession,
                  onSessionSelected: (session) => setState(() => _selectedYesterdaySession = session),
                  onBack: () => setState(() => _selectedYesterdaySession = null),
                ),
                _buildDateTab(),
                _buildStudentsTab(),
              ],
            ),
    );
  }

  Widget _buildDateTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: OutlinedButton.icon(
            onPressed: _isDateLoading ? null : _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_selectedDate == null ? 'Select Date' : DateFormat.yMMMd().format(_selectedDate!)),
          ),
        ),
        Expanded(
          child: _isDateLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedDate == null
                  ? const Center(child: Text('Choose a date to view sessions'))
                  : _buildSessionTab(
                      stats: _dateStats,
                      selectedSession: _selectedDateSession,
                      onSessionSelected: (session) => setState(() => _selectedDateSession = session),
                      onBack: () => setState(() => _selectedDateSession = null),
                    ),
        ),
      ],
    );
  }

  Widget _buildSessionTab({
    required Map<String, dynamic>? stats,
    required Map<String, dynamic>? selectedSession,
    required ValueChanged<Map<String, dynamic>> onSessionSelected,
    required VoidCallback onBack,
  }) {
    if (stats == null) return const Center(child: Text('No data'));
    if (selectedSession != null) return _buildSessionStudents(selectedSession, onBack);

    final sessions = List<Map<String, dynamic>>.from(stats['sessions'] ?? []);
    if (sessions.isEmpty) {
      return Center(child: Text('No sessions for ${stats['date']}'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final count = session['unique_students_present'] ?? session['total_matched'] ?? 0;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Session ${session['session_number']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: TextButton(
            onPressed: () => onSessionSelected(session),
            child: Text('$count Students'),
          ),
        );
      },
    );
  }

  Widget _buildSessionStudents(Map<String, dynamic> session, VoidCallback onBack) {
    final students = List<Map<String, dynamic>>.from(session['students'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Session ${session['session_number']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Belt', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 84, child: Text('Photo', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('No students marked present'))
              : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) => _studentRow(students[index]),
                ),
        ),
      ],
    );
  }

  Widget _studentRow(Map<String, dynamic> student) {
    final photoUrl = student['photo_url'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              onTap: photoUrl == null || photoUrl.isEmpty ? null : () => _showPhotoPreview(student),
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

  Widget _buildStudentsTab() {
    if (_students == null || _students!.isEmpty) return const Center(child: Text('No students enrolled'));
    return ListView.builder(
      itemCount: _students!.length,
      itemBuilder: (context, index) {
        final student = _students![index];
        return ListTile(
          leading: _studentAvatar(student),
          title: Text(student['name']),
          subtitle: Text('Belt: ${student['belt_color']}'),
          onTap: () => _showStudentStats(student['id'], student['name']),
        );
      },
    );
  }

  Widget _studentAvatar(Map<String, dynamic> student) {
    final photoUrl = student['photo_url'] as String?;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return InkWell(
        onTap: () => _showPhotoPreview(student),
        customBorder: const CircleBorder(),
        child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(photoUrl)),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.black,
      child: Text(student['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
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

  void _showPhotoPreview(Map<String, dynamic> student) {
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

  Future<void> _showStudentStats(int studentId, String name) async {
    try {
      final stats = await _api.getStudentStats(studentId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Total Sessions', '${stats['total_sessions']}'),
                _statRow('Present', '${stats['present']}'),
                _statRow('Absent', '${stats['absent']}'),
                _statRow('Attendance', '${stats['attendance_percentage']}%'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
