import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helssa_app/features/chat/data/chat_api.dart';
import 'package:helssa_app/core/constants.dart';

void main() {
  test('send posts message to /chat/msg/', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode({'reply': 'ok'}), 200);
    });

    final api = ChatApi('t', client: client);
    final resp = await api.send(text: 'hi');

    expect(captured.url.toString(), '$baseUrl/chat/msg/');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['message'], 'hi');
    expect(resp['reply'], 'ok');
  });
}
