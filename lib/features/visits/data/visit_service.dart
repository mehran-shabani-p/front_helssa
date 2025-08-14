import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class VisitService {
  VisitService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Map<String, dynamic>>> listVisits(String token) async {
    final uri = Uri.parse('$baseUrl/visit/');
    final r = await _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode != 200) {
      throw Exception('Visit list failed: ${r.statusCode}');
    }
    final data = jsonDecode(r.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  Future<void> requestVisit(String token, Map<String, dynamic> form) async {
    final uri = Uri.parse('$baseUrl/visit/');
    final r = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(form),
    );
    if (r.statusCode != 200) {
      throw Exception('Visit request failed: ${r.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> previousPrescriptions(String token, String nationalCode) async {
    final uri = Uri.parse('$baseUrl/order/download/$nationalCode/');
    final r = await _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode != 200) {
      throw Exception('Prescriptions failed: ${r.statusCode}');
    }
    final data = jsonDecode(r.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }
}
