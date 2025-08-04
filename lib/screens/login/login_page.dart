// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme_provider.dart';
import '../../utils/snackbar.dart';
import '../main_screen.dart';
import 'login_widgets.dart';
import 'particles_background.dart';
import '../../constants.dart';

const int _credentialValiditySeconds = 300;

// --- رنگ‌های سبز ---
class LoginColors {
  static const primaryGreen = Color(0xFF2E7D66);     // سبز دریایی
  static const lightGreen = Color(0xFF4CAF50);       // سبز روشن
  static const darkGreen = Color(0xFF1B5E20);        // سبز تیره
  static const paleGreen = Color(0xFFE8F7E8);        // سبز کم‌رنگ
  static const softGreen = Color(0xFF66BB6A);        // سبز ملایم
  static const backgroundGreen = Color(0xFF0D4F3C);  // پس‌زمینه سبز تیره
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  /* ------------------------ Controllers & State ------------------------ */
  final _phoneFormKey        = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();
  final _phoneController     = TextEditingController();
  final _codeController      = TextEditingController();
  final _phoneFocusNode      = FocusNode();
  final _codeFocusNode       = FocusNode();

  late final AnimationController _animationController;
  late final AnimationController _shimmerController;
  late final Animation<double>   _fadeAnimation;
  late final Animation<double>   _shimmerAnimation;

  bool _isLoading            = false;
  bool _isVerifying          = false;
  bool _isExpandedBackground = false;
  bool _obscureCode          = true;
  bool _canResendCode        = false;
  int  _resendCooldown       = 60;
  bool _hasStoredCredentials = false;
 
  

  Timer? _backgroundTimer;
  Timer? _resendTimer;
  final _random = Random();

  /* ------------------------------- Init -------------------------------- */
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeScreen();
    _checkStoredCredentials();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    _backgroundTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  /* ------------------------- UI Initialisation ------------------------ */
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // انیمیشن درخشان برای متن HELSSA
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linearToEaseOut),
    );
  }

  void _initializeScreen() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: LoginColors.backgroundGreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _startBackgroundAnimation();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    _phoneFocusNode.addListener(() => setState(() {}));
    _codeFocusNode.addListener(()  => setState(() {}));
  }

  void _startBackgroundAnimation() {
    _backgroundTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => mounted ? setState(() => _isExpandedBackground = !_isExpandedBackground) : null,
    );
  }

  /* ---------------------- Stored Credentials Check -------------------- */
  Future<void> _checkStoredCredentials() async {
    final prefs   = await SharedPreferences.getInstance();
    final phone   = prefs.getString('phone_number');
    final code    = prefs.getString('verification_code');
    final savedAt = prefs.getInt('credentials_saved_at');
    final nowMs   = DateTime.now().millisecondsSinceEpoch;
    final isValid = savedAt != null && (nowMs - savedAt) < _credentialValiditySeconds * 1000;

    if (!isValid) {
      prefs
        ..remove('access_token')
        ..remove('phone_number')
        ..remove('verification_code')
        ..remove('credentials_saved_at');
      setState(() => _hasStoredCredentials = false);
      return;
    }

    setState(() {
      _hasStoredCredentials = phone != null && code != null;
      if (_hasStoredCredentials) {
        _phoneController.text = phone!;
        _codeController.text  = code!;
      }
    });
  }

  /* ---------------------- API: Register & Verify ---------------------- */
  Future<void> _registerPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/register/'),
        headers: {'Content-Type':'application/json; charset=UTF-8'},
        body: jsonEncode({'phone_number': _phoneController.text}),
      );
      if (resp.statusCode == 200) {
        setState(() => _isVerifying = true);
        _animationController.forward();
        _startResendTimer();
      } else {
        CustomSnackBar.show('خطا در ثبت شماره. دوباره تلاش کنید', context, isError: true);
      }
    } catch (_) {
      CustomSnackBar.show('خطا در ارتباط با سرور. دوباره تلاش کنید', context, isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyCode() async {
    if (!_verificationFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/verify/'),
        headers: {'Content-Type':'application/json; charset=UTF-8'},
        body: jsonEncode({'phone_number': _phoneController.text, 'code': _codeController.text}),
      );
      if (resp.statusCode == 200) {
        final data  = json.decode(resp.body);
        final prefs = await SharedPreferences.getInstance();
        prefs
          ..setString('access_token', data['access'])
          ..setString('phone_number', _phoneController.text)
          ..setString('verification_code', _codeController.text)
          ..setInt   ('credentials_saved_at', DateTime.now().millisecondsSinceEpoch);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, _) => const MainScreen(),
              transitionsBuilder: (_, anim, _, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      } else {
        CustomSnackBar.show('کد وارد شده نامعتبر است. دوباره تلاش کنید', context, isError: true);
      }
    } catch (_) {
      CustomSnackBar.show('خطا در ارتباط با سرور. دوباره تلاش کنید', context, isError: true);
    }
    setState(() => _isLoading = false);
  }

  /* -------------------------- Logout & Resend ------------------------- */
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs
      ..remove('access_token')
      ..remove('phone_number')
      ..remove('verification_code')
      ..remove('credentials_saved_at');

    _resendTimer?.cancel();

    setState(() {
      _phoneController.clear();
      _codeController.clear();
      _hasStoredCredentials = false;
      _isVerifying          = false;
      _canResendCode        = false;
      _resendCooldown       = 60;
      _animationController.reverse();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _canResendCode  = false;
      _resendCooldown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown == 0) {
        setState(() => _canResendCode = true);
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (!_canResendCode) return;
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/register/'),
        headers: {'Content-Type':'application/json; charset=UTF-8'},
        body: jsonEncode({'phone_number': _phoneController.text}),
      );
      if (resp.statusCode == 200) {
        CustomSnackBar.show('کد تایید مجدداً ارسال شد', context);
        _startResendTimer();
      } else {
        CustomSnackBar.show('خطا در ارسال مجدد کد. دوباره تلاش کنید', context, isError: true);
      }
    } catch (_) {
      CustomSnackBar.show('خطا در ارتباط با سرور. دوباره تلاش کنید', context, isError: true);
    }
    setState(() => _isLoading = false);
  }

  /* ---------------------------- Validators ---------------------------- */
  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty)            return 'لطفا شماره موبایل را وارد کنید';
    if (!RegExp(r'^09[0-9]{9}$').hasMatch(v)) return 'شماره موبایل نامعتبر است';
    return null;
  }

  String? _validateVerificationCode(String? v) {
    if (v == null || v.isEmpty)             return 'لطفا کد تایید را وارد کنید';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(v)) return 'کد تایید نامعتبر است';
    return null;
  }

  /* -------------------------- Shimmer Title --------------------------- */
  Widget _buildShimmerTitle() {
    return Center(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.transparent,
                  LoginColors.lightGreen,
                  Colors.white,
                  LoginColors.lightGreen,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                begin: Alignment(_shimmerAnimation.value - 1, 0),
                end: Alignment(_shimmerAnimation.value, 0),
              ).createShader(bounds);
            },
            child: const Text(
              'HELSSA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /* ------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_hasStoredCredentials) return false;
        if (_isVerifying) {
          _resendTimer?.cancel();
          setState(() {
            _isVerifying    = false;
            _canResendCode  = false;
            _resendCooldown = 60;
            _animationController.reverse();
          });
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () {
          _phoneFocusNode.unfocus();
          _codeFocusNode.unfocus();
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          /* -------------------------- APP BAR --------------------------- */
          appBar: AppBar(
            toolbarHeight: 50,
            leading: IconButton(
              icon: Icon(Icons.arrow_circle_left, color: LoginColors.lightGreen),
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const MainScreen())
              ),
            ),
            title: _buildShimmerTitle(),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          /* -------------------------------------------------------------- */
          backgroundColor: LoginColors.backgroundGreen,
          body: Stack(
            children: [
              ParticlesBackground(
                isExpanded: _isExpandedBackground,
                primaryColor: LoginColors.primaryGreen,
                random: _random,
              ),
              LoginMainContent(
                hasStoredCredentials: _hasStoredCredentials,
                isVerifying: _isVerifying,
                isLoading: _isLoading,
                phoneController: _phoneController,
                codeController: _codeController,
                phoneFormKey: _phoneFormKey,
                verificationFormKey: _verificationFormKey,
                phoneFocusNode: _phoneFocusNode,
                codeFocusNode: _codeFocusNode,
                onRegisterPhone: _registerPhone,
                onVerifyCode: _verifyCode,
                onLogout: _logout,
                canResendCode: _canResendCode,
                resendCooldown: _resendCooldown,
                resendCode: _resendCode,
                obscureCode: _obscureCode,
                setObscureCode: (v) => setState(() => _obscureCode = v),
                fadeAnimation: _fadeAnimation,
                primaryColor: LoginColors.primaryGreen,
                validatePhone: _validatePhone,
                validateVerificationCode: _validateVerificationCode,
              ),
              if (_isLoading) LoadingOverlay(primaryColor: LoginColors.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}

