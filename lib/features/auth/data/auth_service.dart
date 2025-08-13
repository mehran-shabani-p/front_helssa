import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class AuthService {
  Future<void> requestOtp(String phone) async {
    final uri = Uri.parse('$baseUrl/auth/request-otp');
    final r = await http.post(uri, headers: {'Content-Type':'application/json'}, body: jsonEncode({'phone': phone}));
    if (r.statusCode != 200) throw Exception('OTP request failed: ${r.statusCode}');
  }

  Future<String> login({required String phone, required String otp}) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final r = await http.post(uri, headers: {'Content-Type':'application/json'}, body: jsonEncode({'phone': phone, 'otp': otp}));
    if (r.statusCode != 200) throw Exception('Login failed: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['access_token'] ?? data['token'] ?? '').toString();
  }
}
