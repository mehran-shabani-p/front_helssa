import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helssa_app/features/profile/data/profile_service.dart';
import 'package:helssa_app/core/constants.dart';

void main() {
  test('fetchProfile posts to /profile/ and parses response', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'username': 'u'}), 200);
    });

    final service = ProfileService(client: client);
    final data = await service.fetchProfile('token');

    expect(captured.method, 'POST');
    expect(captured.url.toString(), '$baseUrl/profile/');
    expect(captured.headers['Authorization'], 'Bearer token');
    expect(data['username'], 'u');
  });

  test('updateProfile posts to /profile/update/', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('', 200);
    });

    final service = ProfileService(client: client);
    await service.updateProfile('token', {'username': 'new', 'email': 'e'});

    expect(captured.url.toString(), '$baseUrl/profile/update/');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['username'], 'new');
    expect(body['email'], 'e');
  });
}
