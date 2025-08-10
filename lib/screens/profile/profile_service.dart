// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';

/* ============================================================================
ProfileService - مدیریت عملیات پروفایل و کیف پول
===========================================================================*/

class ProfileService {

  static const String _baseUrl = '$baseUrl';

  /* ========================================================================
  دریافت توکن دسترسی
  ======================================================================== */
  
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /* ========================================================================
  Headers پیش‌فرض برای درخواست‌ها
  ======================================================================== */
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  /* ========================================================================
  دریافت اطلاعات پروفایل و کیف پول
  ======================================================================== */
  
  static Future<Map<String, dynamic>> fetchProfileAndWallet() async {
    try {
      final headers = await _getHeaders();
      
      final responses = await Future.wait([
        http.post(
          Uri.parse('$_baseUrl/api/profile/'),
          headers: headers,
        ),
        http.post(
          Uri.parse('$_baseUrl/api/box/'),
          headers: headers,
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final profile = json.decode(responses[0].body);
        final walletData = json.decode(responses[1].body);
        
        return {
          'success': true,
          'profile': profile,
          'walletAmount': walletData['amount'].toDouble(),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در دریافت اطلاعات پروفایل یا کیف پول!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  به‌روزرسانی پروفایل کاربر
  ======================================================================== */
  
  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String email,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/profile/update/'),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'profile': json.decode(response.body),
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'errors': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در به‌روزرسانی پروفایل (کد: ${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  ایجاد لینک پرداخت
  ======================================================================== */
  
  static Future<Map<String, dynamic>> createPaymentLink(int amount) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transaction/'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['payment_url'] != null) {
          return {
            'success': true,
            'paymentUrl': data['payment_url'],
          };
        } else {
          return {
            'success': false,
            'error': 'لینک پرداخت در پاسخ سرور یافت نشد',
          };
        }
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'خطا در دریافت لینک پرداخت',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  باز کردن لینک پرداخت
  ======================================================================== */
  
  static Future<bool> launchPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /* ========================================================================
  دریافت فقط اطلاعات پروفایل
  ======================================================================== */
  
  static Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'profile': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در دریافت اطلاعات پروفایل',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  دریافت فقط اطلاعات کیف پول
  ======================================================================== */
  
  static Future<Map<String, dynamic>> fetchWallet() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/box/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'walletAmount': data['amount'].toDouble(),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در دریافت اطلاعات کیف پول',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  تاریخچه تراکنش‌ها (اختیاری - برای آینده)
  ======================================================================== */
  
  static Future<Map<String, dynamic>> fetchTransactionHistory() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'transactions': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در دریافت تاریخچه تراکنش‌ها',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  حذف حساب کاربری (اختیاری - برای آینده)
  ======================================================================== */
  
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/profile/delete/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'حساب کاربری با موفقیت حذف شد',
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در حذف حساب کاربری',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  تأیید پرداخت (اختیاری - برای آینده)
  ======================================================================== */
  
  static Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transaction/verify/'),
        headers: headers,
        body: jsonEncode({'transaction_id': transactionId}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'خطا در تأیید پرداخت',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در ارتباط با سرور: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
  کنترل وضعیت سرور
  ======================================================================== */
  
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /* ========================================================================
  خروج از حساب کاربری
  ======================================================================== */
  
  static Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      
      return {
        'success': true,
        'message': 'با موفقیت خارج شدید',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در خروج از حساب: ${e.toString()}',
      };
    }
  }

  /* ========================================================================
دریافت لیست پلن‌های اشتراک
======================================================================== */

static Future<Map<String, dynamic>> fetchSubscriptionPlans() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/sub/plans/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> plans = json.decode(response.body);
      // فیلتر کردن پلن starter
      final filteredPlans = plans.where((plan) => plan['name'] != 'starter').toList();
      
      return {
        'success': true,
        'plans': filteredPlans,
      };
    } else {
      return {
        'success': false,
        'error': 'خطا در دریافت لیست پلن‌ها',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'خطا در ارتباط با سرور: ${e.toString()}',
    };
  }
}

/* ========================================================================
دریافت اشتراک فعلی کاربر
======================================================================== */

static Future<Map<String, dynamic>> fetchUserSubscription() async {
  try {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/sub/my-subscription/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'subscription': json.decode(response.body),
      };
    } else if (response.statusCode == 404) {
      return {
        'success': true,
        'subscription': null, // کاربر اشتراک فعالی ندارد
      };
    } else {
      return {
        'success': false,
        'error': 'خطا در دریافت اطلاعات اشتراک',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'خطا در ارتباط با سرور: ${e.toString()}',
    };
  }
}

/* ========================================================================
خرید اشتراک جدید
======================================================================== */

static Future<Map<String, dynamic>> buySubscription(int planId) async {
  try {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/sub/buy/'),
      headers: headers,
      body: jsonEncode({'plan_id': planId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'subscription': json.decode(response.body),
      };
    } else {
      final error = json.decode(response.body);
      return {
        'success': false,
        'error': error['detail'] ?? 'خطا در خرید اشتراک',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'خطا در ارتباط با سرور: ${e.toString()}',
    };
  }
}


    static Future<Map<String, dynamic>> submitReferralCode(String phoneNumber) async {
      try {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('$_baseUrl/api/intcode/'),
          headers: headers,
          body: jsonEncode({'phone': phoneNumber}),
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            return {
              'success': true,
              'message': 'کد معرف با موفقیت ثبت شد',
            };
            } else {
              final error = json.decode(response.body);
              return {
                'success': false,
                'error': error['detail'] ?? 'خطا در ثبت کد معرف',
                };}
                } catch (e) {
                  return {
                    'success': false,
                    'error': 'خطا در ارتباط با سرور: ${e.toString()}'
                    };
                    }
                    }
                    }