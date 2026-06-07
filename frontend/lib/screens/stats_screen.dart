import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _weekStats;
  Map<String, dynamic>? _monthStats;
  List<dynamic>? _students;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getDayStats(),
        _api.getWeekStats(),
        _api.getMonthStats(),
        _api.getStudents(),
      ]);
      setState(() {
        _dayStats = results[0] as Map<String, dynamic>;
        _weekStats = results[1] as Map<String, dynamic>;
        _monthStats = results[2] as Map<String, dynamic>;
        _students = results[3] as List<dynamic>;
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
            Tab(text: 'Week'),
            Tab(text: 'Month'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDayTab(),
                _buildWeekTab(),
                _buildMonthTab(),
                _buildStudentsTab(),
              ],
            ),
    );
  }

  Widget _buildDayTab() {
    if (_dayStats == null) return const Center(child: Text('No data'));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: ${_dayStats!['date']}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          _statRow('Total Sessions', '${_dayStats!['total_sessions']}'),
          _statRow('Unique Students Present', '${_dayStats!['unique_students_present']}'),
          const SizedBox(height: 16),
          const Text('Sessions:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_dayStats!['sessions'] as List).map((s) => ListTile(
                title: Text('Session ${s['session_number']}'),
                subtitle: Text('Detected: ${s['total_detected']} | Matched: ${s['total_matched']}'),
              )),
        ],
      ),
    );
  }

  Widget _buildWeekTab() {
    if (_weekStats == null) return const Center(child: Text('No data'));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_weekStats!['week_start']} to ${_weekStats!['week_end']}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          _statRow('Total Sessions', '${_weekStats!['total_sessions']}'),
          _statRow('Unique Students Present', '${_weekStats!['unique_students_present']}'),
        ],
      ),
    );
  }

  Widget _buildMonthTab() {
    if (_monthStats == null) return const Center(child: Text('No data'));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Month: ${_monthStats!['month']}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          _statRow('Total Sessions', '${_monthStats!['total_sessions']}'),
          _statRow('Unique Students', '${_monthStats!['unique_students_present']}'),
          _statRow('Days with Sessions', '${_monthStats!['total_days_with_sessions']}'),
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
          leading: CircleAvatar(
            backgroundColor: Colors.black,
            child: Text(student['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(student['name']),
          subtitle: Text('Belt: ${student['belt_color']}'),
          onTap: () => _showStudentStats(student['id'], student['name']),
        );
      },
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
}
