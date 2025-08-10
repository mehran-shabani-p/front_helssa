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
  static const _minSplash = Duration(seconds: 3);
  static const _currentVersion = currentVersion;

  /* ===== State ===== */
  bool _navigated = false;
  late final DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
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
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (_, _, _) => const LoginPage(),
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return FadeTransition(
            opacity: curved,
            child: RotationTransition(
              turns: Tween<double>(begin: .85, end: 1).animate(curved),
              child: child,
            ),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SplashColors.darkGreen.withOpacity(0.95),
                SplashColors.primaryGreen.withOpacity(0.95),
                SplashColors.softGreen.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: SplashColors.lightGreen.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: SplashColors.lightGreen.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          gradient: LinearGradient(
                            colors: [
                              SplashColors.lightGreen,
                              SplashColors.softGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SplashColors.lightGreen.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
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
                          gradient: LinearGradient(
                            colors: [
                              SplashColors.lightGreen.withOpacity(0.2),
                              SplashColors.softGreen.withOpacity(0.2),
                            ],
                          ),
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
                          _modernWebButton('🔄 بازآوری صفحه', _reloadWebApp),
                          const SizedBox(height: 12),
                          _modernSecondaryButton('🤔 بعداً', () {
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
        ),
      ),
    );
  }

  /* ---------- دیالوگ آپدیت اندروید (همان کد قبلی) ---------- */
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SplashColors.darkGreen.withOpacity(0.95),
                SplashColors.primaryGreen.withOpacity(0.95),
                SplashColors.softGreen.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: SplashColors.lightGreen.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: SplashColors.lightGreen.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          gradient: LinearGradient(
                            colors: [
                              SplashColors.lightGreen,
                              SplashColors.softGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SplashColors.lightGreen.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
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
                          gradient: LinearGradient(
                            colors: [
                              SplashColors.lightGreen.withOpacity(0.2),
                              SplashColors.softGreen.withOpacity(0.2),
                            ],
                          ),
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
                        _modernPrimaryButton('🚀 دانلود نسخه جدید', _launchDownload)
                      else
                        Column(
                          children: [
                            _modernPrimaryButton('🔥 دانلود و نصب', () {
                              _launchDownload();
                              _goLogin();
                            }),
                            const SizedBox(height: 12),
                            _modernSecondaryButton('🤔 فعلاً نه', () {
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
        ),
      ),
    );
  }

  /* ---------- دکمه‌های مدرن ---------- */
  Widget _modernPrimaryButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SplashColors.lightGreen,
            SplashColors.softGreen,
            SplashColors.primaryGreen,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SplashColors.lightGreen.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernWebButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SplashColors.lightGreen,
            SplashColors.softGreen,
            SplashColors.primaryGreen,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SplashColors.lightGreen.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernSecondaryButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SplashColors.lightGreen.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.vazirmatn(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- ریفرش وب اپلیکیشن ---------- */
  void _reloadWebApp() {
    if (kIsWeb) {
      // Hard reload برای پاک شدن کش و بارگذاری نسخه جدید
      html.window.location.reload();
    }
  }

  /* ---------- دانلود APK (فقط اندروید) ---------- */
  Future<void> _launchDownload() async =>
      launchUrl(Uri.parse(_dlUrl), mode: LaunchMode.externalApplication);

  /* ---------- UI (particles + logo + version) ---------- */
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SplashColors.backgroundGreen,
        body: AnimatedBuilder(
          animation: _ctl,
          builder: (_, _) => Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SplashColors.backgroundGreen,
                      SplashColors.darkGreen,
                      SplashColors.primaryGreen.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              // Particles
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlesPainter(_ctl.value),
              ),
              // Logo
              Center(child: _logoAnimator()),
              // Version
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
        ),
      );

  Widget _logoAnimator() => TweenAnimationBuilder<double>(
        tween: Tween(begin: .97, end: 1.03),
        duration: const Duration(seconds: 4),
        curve: Curves.easeInOut,
        builder: (_, _, _) => Transform.scale(
          scale: 1 + 0.02 * sin(_ctl.value * pi),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: SplashColors.lightGreen.withOpacity(.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const SizedBox(width: 300, height: 120),
              ),
              // Main logo text
              ShaderMask(
                shaderCallback: (bounds) {
                  final progress = (_ctl.value) % 1;
                  return LinearGradient(
                    colors: const [
                      SplashColors.lightGreen,
                      SplashColors.softGreen,
                      SplashColors.paleGreen,
                      SplashColors.lightGreen,
                    ],
                    stops: [
                      0.0,
                      progress.clamp(0.0, 1.0),
                      (progress + 0.1).clamp(0.0, 1.0),
                      1.0,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  'HELSSA',
                  style: GoogleFonts.orbitron(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: SplashColors.primaryGreen.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/* ---------- Particles painter ---------- */
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final _rand = Random();
  _ParticlesPainter(this.progress);

  @override
  void paint(Canvas c, Size s) {
    const n = 25;
    for (var i = 0; i < n; i++) {
      final t = (progress + i / n) % 1;
      final x = s.width * (.2 + .6 * _rand.nextDouble()) + 30 * sin(t * pi + i);
      final y = s.height * (.2 + .6 * _rand.nextDouble()) + 25 * cos(t * pi + i);
      final r = 1.5 + 2 * sin(t * pi);
      final op = .04 + .15 * (1 + sin((progress + i) * pi));
      
      // رنگ‌های مختلف سبز برای پارتیکل‌ها
      Color particleColor;
      if (i % 3 == 0) {
        particleColor = SplashColors.lightGreen;
      } else if (i % 3 == 1) {
        particleColor = SplashColors.softGreen;
      } else {
        particleColor = SplashColors.primaryGreen;
      }
      
      // پارتیکل اصلی
      c.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = particleColor.withOpacity(op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) =>
      old.progress != progress;
}