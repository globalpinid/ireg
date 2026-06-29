import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Set API_URL at build time: flutter build web --dart-define=API_URL=https://your-backend.railway.app
  // Defaults to localhost for development
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

  Future<Map<String, dynamic>> enrollStudent({
    required String name,
    required String beltColor,
    required Uint8List photoBytes,
    required String fileName,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/students/enroll'));
    request.fields['name'] = name;
    request.fields['belt_color'] = beltColor;
    request.files.add(http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName));
    var response = await request.send();
    var body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> markAttendance({
    required Uint8List photoBytes,
    required String fileName,
    int sessionNumber = 1,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/attendance/mark'));
    request.fields['session_number'] = sessionNumber.toString();
    request.files.add(http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName));
    var response = await request.send();
    var body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  Future<List<dynamic>> getStudents() async {
    var response = await http.get(Uri.parse('$baseUrl/students/'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getDayStats({String? date}) async {
    var url = '$baseUrl/stats/day';
    if (date != null) url += '?target_date=$date';
    var response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getYesterdayStats() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final date =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return getDayStats(date: date);
  }

  Future<Map<String, dynamic>> getWeekStats() async {
    var response = await http.get(Uri.parse('$baseUrl/stats/week'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMonthStats({int? year, int? month}) async {
    var url = '$baseUrl/stats/month';
    var params = <String>[];
    if (year != null) params.add('year=$year');
    if (month != null) params.add('month=$month');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    var response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getStudentStats(int studentId) async {
    var response = await http.get(Uri.parse('$baseUrl/stats/student/$studentId'));
    return jsonDecode(response.body);
  }
}
