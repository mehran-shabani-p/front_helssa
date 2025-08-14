import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<void> requestOtp(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/register/');
    final r = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );
    if (r.statusCode != 200) {
      throw Exception('OTP request failed: ${r.statusCode}');
    }
  }

  Future<String> login({required String phoneNumber, required String code}) async {
    final uri = Uri.parse('$baseUrl/verify/');
    final r = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'code': code}),
    );
    if (r.statusCode != 200) {
      throw Exception('Login failed: ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['access_token'] ?? data['token'] ?? '').toString();
  }
}
