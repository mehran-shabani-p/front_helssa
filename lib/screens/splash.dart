// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'login/login_page.dart';
import '../../constants.dart';

// اگر پلتفرم اندروید بود
import 'dart:io' show Platform;

// --- رنگ‌های سبز ---
class SplashColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFF0D4F3C);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /* ===== نسخهٔ فعلی اپ؛ هر ریلیز به‌روز شود ===== */
  
   
  /* ===== Animation ===== */
  late final AnimationController _ctl;

  /* ===== شبکه ===== */
  static const _apiUrl = '$baseUrl/down/status/';
  static const _dlUrl  = '$baseUrl/api/download-apk/';
  static const _timeout = Duration(seconds: 3);
  static const _minSplash = Duration(seconds: 2); // کاهش زمان اسپلش
  static const _currentVersion = currentVersion;

  /* ===== State ===== */
  bool _navigated = false;
  late final DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    // کاهش زمان انیمیشن
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    
    // چک آپدیت برای هر دو پلتفرم
    _checkUpdate();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  /* ---------- تشخیص پلتفرم ---------- */
  bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /* ---------- مقایسهٔ نسخه ---------- */
  bool _isNewer(String server, String local) {
    final s = server.split('.').map(int.parse).toList();
    final l = local.split('.').map(int.parse).toList();
    for (var i = 0; i < max(s.length, l.length); i++) {
      final sv = i < s.length ? s[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (sv > lv) return true;
      if (sv < lv) return false;
    }
    return false;
  }

  /* ---------- فراخوانی API (مشترک برای وب و اندروید) ---------- */
  Future<void> _checkUpdate() async {
    bool flag = false;
    bool force = false;
    String serverVer = _currentVersion;
    String releaseNotes = '';

    try {
      final resp = await http.get(Uri.parse(_apiUrl)).timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        flag         = data['update_available'] == true;
        serverVer    = data['version'] ?? _currentVersion;
        force        = data['force_update'] ?? false;
        releaseNotes = data['release_notes'] ?? '';
      }
    } catch (_) {
      // خطا در دریافت اطلاعات - ادامه بدون آپدیت
    }

    final need = flag && _isNewer(serverVer, _currentVersion);

    /* حداقل زمان اسپلش */
    final gap = DateTime.now().difference(_start);
    final wait = gap < _minSplash ? _minSplash - gap : Duration.zero;
    await Future.delayed(wait);
    if (!mounted) return;

    if (need) {
      if (kIsWeb) {
        _showWebUpdateDialog(serverVer, releaseNotes);
      } else if (_isAndroid) {
        _showAndroidUpdateDialog(force, serverVer, releaseNotes);
      } else {
        // سایر پلتفرم‌ها (iOS و...) - فعلاً مستقیم به لاگین
        _goLogin();
      }
    } else {
      _goLogin();
    }
  }

  /* ---------- ناوبری ---------- */
  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        // کاهش زمان انیمیشن
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => const LoginPage(),
        transitionsBuilder: (_, anim, _, child) {
          // ساده‌تر کردن انیمیشن
          return FadeTransition(
            opacity: anim,
            child: child,
          );
        },
      ),
    );
  }

  /* ---------- دیالوگ آپدیت وب ---------- */
  void _showWebUpdateDialog(String serverVersion, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: SplashColors.backgroundGreen.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: SplashColors.primaryGreen, // ساده‌تر کردن پس‌زمینه
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: SplashColors.lightGreen.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: SplashColors.lightGreen, // ساده‌تر کردن گرادیانت
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.web_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // عنوان
                  Text(
                    '🌐 نسخه جدید وب اپلیکیشن',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // نسخه جدید
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: SplashColors.lightGreen.withOpacity(0.2), // ساده‌تر کردن گرادیانت
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SplashColors.lightGreen.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.new_releases_rounded,
                          color: SplashColors.paleGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'نسخه $serverVersion',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SplashColors.paleGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // پیام اصلی
                  Text(
                    'نسخه جدید هلسا منتشر شده است.\nبرای دریافت آخرین ویژگی‌ها، لطفاً صفحه را بازآوری کنید.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                  
                  // نمایش Release Notes
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: SplashColors.lightGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.article_rounded,
                                color: SplashColors.lightGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تغییرات جدید:',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: SplashColors.lightGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            releaseNotes,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // دکمه‌ها
                  Column(
                    children: [
                      _simpleWebButton('🔄 بازآوری صفحه', _reloadWebApp),
                      const SizedBox(height: 12),
                      _simpleSecondaryButton('🤔 بعداً', () {
                        Navigator.pop(context);
                        _goLogin();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- دیالوگ آپدیت اندروید (ساده‌تر شده) ---------- */
  void _showAndroidUpdateDialog(bool force, String serverVersion, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      barrierColor: SplashColors.backgroundGreen.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: SplashColors.primaryGreen, // ساده‌تر کردن پس‌زمینه
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: SplashColors.lightGreen.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: SplashColors.lightGreen, // ساده‌تر کردن گرادیانت
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // عنوان
                  Text(
                    force ? '🎯 به‌روزرسانی ضروری' : '✨ نسخه جدید آماده است',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // نسخه جدید
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: SplashColors.lightGreen.withOpacity(0.2), // ساده‌تر کردن گرادیانت
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SplashColors.lightGreen.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.new_releases_rounded,
                          color: SplashColors.paleGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'نسخه $serverVersion',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SplashColors.paleGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // پیام اصلی
                  Text(
                    force 
                        ? 'برای ادامه استفاده از هلسا، لطفاً نسخه جدید را دانلود کنید.'
                        : 'نسخه جدید هلسا با ویژگی‌های جذاب منتظر شماست!',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                  
                  // نمایش Release Notes
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: SplashColors.lightGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.article_rounded,
                                color: SplashColors.lightGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ویژگی‌های جدید:',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: SplashColors.lightGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            releaseNotes,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // دکمه‌ها
                  if (force)
                    _simplePrimaryButton('🚀 دانلود نسخه جدید', _launchDownload)
                  else
                    Column(
                      children: [
                        _simplePrimaryButton('🔥 دانلود و نصب', () {
                          _launchDownload();
                          _goLogin();
                        }),
                        const SizedBox(height: 12),
                        _simpleSecondaryButton('🤔 فعلاً نه', () {
                          Navigator.pop(context);
                          _goLogin();
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- دکمه‌های ساده‌تر ---------- */
  Widget _simplePrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SplashColors.lightGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.vazirmatn(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _simpleWebButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SplashColors.lightGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.vazirmatn(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.vazirmatn(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /* ---------- ریفرش وب اپلیکیشن ---------- */
  void _reloadWebApp() {
    if (kIsWeb) {
      html.window.location.reload();
    }
  }

  /* ---------- دانلود APK (فقط اندروید) ---------- */
  Future<void> _launchDownload() async =>
      launchUrl(Uri.parse(_dlUrl), mode: LaunchMode.externalApplication);

  /* ---------- UI (ساده‌تر شده) ---------- */
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SplashColors.backgroundGreen,
        body: Stack(
          children: [
            // پس‌زمینه ساده
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SplashColors.backgroundGreen,
                    SplashColors.darkGreen,
                  ],
                ),
              ),
            ),
            // لوگو ساده‌تر
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glow effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SplashColors.darkGreen.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'HELSSA',
                      style: GoogleFonts.orbitron(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // نسخه
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'version $_currentVersion',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    kIsWeb ? 'Web App' : 'Mobile App',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}