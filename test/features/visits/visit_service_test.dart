import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:helssa_app/features/visits/data/visit_service.dart';
import 'package:helssa_app/core/constants.dart';

void main() {
  test('listVisits GETs /visit/', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode([]), 200);
    });

    final service = VisitService(client: client);
    await service.listVisits('t');

    expect(captured.method, 'GET');
    expect(captured.url.toString(), '$baseUrl/visit/');
  });

  test('requestVisit POSTs form to /visit/', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('', 200);
    });

    final service = VisitService(client: client);
    await service.requestVisit('t', {'name': 'n'});

    expect(captured.url.toString(), '$baseUrl/visit/');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['name'], 'n');
  });

  test('previousPrescriptions GETs order download', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(jsonEncode([]), 200);
    });

    final service = VisitService(client: client);
    await service.previousPrescriptions('t', '001');

    expect(captured.url.toString(), '$baseUrl/order/download/001/');
  });
}
