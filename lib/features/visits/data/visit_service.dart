import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class VisitService {
  Future<List<Map<String, dynamic>>> listVisits(String token) async {
    final uri = Uri.parse('$baseUrl/visits');
    final r = await http.get(uri, headers: {'Authorization':'Bearer $token'});
    if (r.statusCode != 200) throw Exception('Visit list failed: ${r.statusCode}');
    final data = jsonDecode(r.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  Future<void> requestVisit(String token, Map<String, dynamic> form) async {
    final uri = Uri.parse('$baseUrl/visits/request');
    final r = await http.post(uri, headers: {'Authorization':'Bearer $token','Content-Type':'application/json'}, body: jsonEncode(form));
    if (r.statusCode != 200) throw Exception('Visit request failed: ${r.statusCode}');
  }

  Future<List<Map<String, dynamic>>> previousPrescriptions(String token) async {
    final uri = Uri.parse('$baseUrl/prescriptions');
    final r = await http.get(uri, headers: {'Authorization':'Bearer $token'});
    if (r.statusCode != 200) throw Exception('Prescriptions failed: ${r.statusCode}');
    final data = jsonDecode(r.body);
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }
}
