import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class ProfileService {
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final uri = Uri.parse('$baseUrl/profile/me');
    final r = await http.get(uri, headers: {'Authorization':'Bearer $token'});
    if (r.statusCode != 200) throw Exception('Fetch profile failed: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> updateProfile(String token, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/profile/update');
    final r = await http.put(uri, headers: {'Authorization':'Bearer $token','Content-Type':'application/json'}, body: jsonEncode(data));
    if (r.statusCode != 200) throw Exception('Update failed: ${r.statusCode}');
  }
}
