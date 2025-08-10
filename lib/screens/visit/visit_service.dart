// visit_service.dart
// منطق شبکه‌ای مرتبط با ویزیت

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';

/// سرویس واحد برای ارسال ویزیت و گرفتن پزشک آن‌کال
class VisitService {
  /* ثابت‌های داخلی */
  static const _baseUrl      = '$baseUrl';
  static const _fixedUrgency = 'prescription';
  static const _fixedSymptom = 'fever';

  /// ارسال ویزیت
  static Future<http.Response> sendVisit({
    required String name,
    required String nationalCode,
    required String details,
    required bool needsCertificate,
    required String contactMethod, // مقدار فارسی یا انگلیسی تفاوتی ندارد
    required String accessToken,
  }) {
    final body = jsonEncode({
      'name'            : name,
      'urgency'         : _fixedUrgency,
      'general_symptoms': _fixedSymptom,
      'description'     : _buildDescription(
        details         : details,
        needsCertificate: needsCertificate,
        contactMethod   : contactMethod,
        nationalCode    : nationalCode,
      ),
    });

    final uri = Uri.parse('$_baseUrl/api/visit/');
    return http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type' : 'application/json; charset=UTF-8',
      },
      body: body,
    );
  }

  static Future<http.StreamedResponse> sendSOSVisit({
  required String visitName,
  required String description,
  required String accessToken,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.medogram.ir/api/super-visit/500000/'),
  );

  request.headers.addAll({'Authorization': 'Bearer $accessToken'});
  request.fields.addAll({
    'name': visitName,
    'urgency': 'prescription',
    'general_symptoms': 'fever',
    'neurological_symptoms': '',
    'cardiovascular_symptoms': '',
    'gastrointestinal_symptoms': '',
    'respiratory_symptoms': '',
    'description': 'اورژانسی - $description',
  });

  return await request.send();
}

  /// دریافت اطلاعات پزشک آن‌کال
  static Future<Map<String, dynamic>?> fetchOnCallDoctor() async {
    final uri = Uri.parse('$_baseUrl/doc/oncall/');
    final res  = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /* توضیح تجمیعی برای فیلد description */
  static String _buildDescription({
    required String details,
    required bool   needsCertificate,
    required String contactMethod,
    required String nationalCode,
  }) {
    String normalize(String t) => t.trim().replaceAll(RegExp(r'\n{2,}'), '\n');
    return '''
📝 جزئیات ویزیت
==========================

${normalize(details)}

==========================

${needsCertificate ? 'نیاز به استعلاجی دارد✅' : ''}

==========================

📞: $contactMethod

==========================

🆔 : $nationalCode

==========================
'''.trim();
  }
}