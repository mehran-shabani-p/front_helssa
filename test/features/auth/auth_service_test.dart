import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helssa_app/features/auth/data/auth_service.dart';
import 'package:helssa_app/core/constants.dart';

void main() {
  test('requestOtp sends phone_number to /register/', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('', 200);
    });

    final service = AuthService(client: client);
    await service.requestOtp('09120000000');

    expect(captured.method, 'POST');
    expect(captured.url.toString(), '$baseUrl/register/');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['phone_number'], '09120000000');
  });

  test('login posts code to /verify/ and returns token', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'token': 'abc'}), 200);
    });

    final service = AuthService(client: client);
    final token = await service.login(phoneNumber: '0912', code: '1234');

    expect(captured.url.toString(), '$baseUrl/verify/');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['phone_number'], '0912');
    expect(body['code'], '1234');
    expect(token, 'abc');
  });
}
