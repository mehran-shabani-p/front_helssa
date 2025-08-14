import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class ChatApi {
  ChatApi(this.accessToken, {http.Client? client})
      : _client = client ?? http.Client();
  final String accessToken;
  final http.Client _client;

  Future<Map<String, dynamic>> send({required String text, List<String> imagesB64 = const []}) async {
    final uri = Uri.parse('$baseUrl/chat/msg/');
    final body = <String, dynamic>{'message': text};
    if (imagesB64.isNotEmpty) body['images'] = imagesB64;

    final resp = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }
}
