// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_a

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/snackbar.dart';
import '../login/login_page.dart';
import 'special_visit_page.dart';
import 'doctor_drawer.dart';
import 'previous_prescriptions_page.dart';
import 'visit_service.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VisitPageState createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> with TickerProviderStateMixin {
/*────────────────────────── کنترلرهای فرم ──────────────────────────*/
  final nameController         = TextEditingController();
  final nationalCodeController = TextEditingController();
  final detailsController      = TextEditingController();

/*──────────────────────────── انیمیشن ورودی ─────────────────────────*/
  late final AnimationController _pageAnimCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..forward();
  late final Animation<double> _fadeAnimation =
      CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeInOut);

  // ✅ انیمیشن پیغام ورودی
  late final AnimationController _welcomeAnimCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final Animation<double> _welcomeSlideAnimation =
      Tween<double>(begin: -1.0, end: 0.0).animate(
        CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeOutBack)
      );
  late final Animation<double> _welcomeOpacityAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeInOut)
      );

  // ✅ انیمیشن SOS چشمک زن
  late final AnimationController _sosAnimCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
  late final Animation<double> _sosAnimation =
      Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _sosAnimCtrl, curve: Curves.easeInOut)
      );

  // ✅ انیمیشن لودینگ دایره ای
  late final AnimationController _loadingAnimCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final Animation<double> _loadingAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loadingAnimCtrl, curve: Curves.easeInOut)
      );

/*────────────────────────────  رنگ‌های بهتر  ─────────────────────────*/
  final _primaryColor    = const Color(0xFF2E7D66);     // سبز دریایی
  final _lightGreen      = const Color(0xFF4CAF50);     // سبز روشن
  final _darkGreen       = const Color(0xFF1B5E20);     // سبز تیره
  final _paleGreen       = const Color(0xFFE8F7E8);     // سبز کم‌رنگ
  final _softGreen       = const Color(0xFF66BB6A);     // سبز ملایم
  final _backgroundGreen = const Color(0xFFF1F8E9);     // پس‌زمینه سبز روشن
  final _specialGreen    = const Color(0xFF00C853);     // سبز ویزیت سریع
  final _sosRed          = const Color(0xFFD32F2F);     // قرمز SOS

/*────────────────────────────  برچسب‌های راه ارتباطی  ────────────────*/
  static const _contactLabels = <String, String>{
    'whatsapp': 'واتس‌اپ',
    'bale'    : 'بله',
    'eitaa'   : 'ایتا',
    'phone'   : 'تلفن',
  };

   static const _visitCost = 300000;

/*────────────────────────────  وضعیت صفحه  ───────────────────────────*/
  final _formKey = GlobalKey<FormState>();
  bool   _loading                 = false;
  bool   _sosLoading              = false; // ✅ لودینگ SOS
  bool   _needsMedicalCertificate = false;
  bool   _isContactExpanded       = false;
  String _contactMethod           = 'whatsapp';
  bool   _copyPreviousPrescription = false;
  bool   _showWelcomeMessage      = true; // ✅ نمایش پیغام ورودی
  bool   _dontShowAgain           = false; // ✅ دیگه نمایش نده

/*──────────────────────────── کلید ExpansionTile ─────────────────────*/
  Key _contactTileKey = UniqueKey();

/*──────────────────────────── پذیرش پزشک آن‌کال ───────────────────────*/
  bool _isDoctorLoading = false;
  OverlayEntry? _doctorOverlay;
  Timer?        _overlayTimer;
  static const _autoHideDuration = Duration(seconds: 4);

/*──────────────────────────── مقداردهی اولیه ───────────────────────────*/
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ✅ بارگذاری تنظیمات ذخیره شده
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool('dont_show_welcome_again') ?? false;
    
    setState(() {
      _dontShowAgain = dontShow;
      _showWelcomeMessage = !dontShow;
    });

    // اگر باید پیغام ورودی نمایش داده بشه
    if (_showWelcomeMessage) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _welcomeAnimCtrl.forward();
      }
    }
  }

  // ✅ ذخیره تنظیمات
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dont_show_welcome_again', _dontShowAgain);
  }

  // ✅ بستن پیغام ورودی
  void _dismissWelcomeMessage({bool dontShowAgain = false}) async {
    if (dontShowAgain) {
      setState(() => _dontShowAgain = true);
      await _savePreferences();
    }
    
    await _welcomeAnimCtrl.reverse();
    setState(() => _showWelcomeMessage = false);
  }

/*──────────────────────────── ریست فرم ───────────────────────────────*/
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      nameController.clear();
      nationalCodeController.clear();
      detailsController.clear();
      _contactMethod            = 'whatsapp';
      _needsMedicalCertificate  = false;
      _copyPreviousPrescription = false;
      _isContactExpanded        = false;
      _contactTileKey           = UniqueKey();
    });
    FocusScope.of(context).unfocus();
  }

/*──────────────────────────── ارسال ویزیت ────────────────────────────*/
  Future<void> _sendVisit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    _loadingAnimCtrl.forward(); // ✅ شروع انیمیشن لودینگ

    final prefs       = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null || accessToken.isEmpty) {
      CustomSnackBar.show('توکن دسترسی پیدا نشد.', context, isError: true);
      setState(() => _loading = false);
      _loadingAnimCtrl.reset(); // ✅ ریست انیمیشن
      return;
    }

    try {
      final res = await VisitService.sendVisit(
        name            : nameController.text,
        nationalCode    : nationalCodeController.text,
        details         : detailsController.text,
        needsCertificate: _needsMedicalCertificate,
        contactMethod   : _contactLabels[_contactMethod]!,
        accessToken     : accessToken,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        CustomSnackBar.show('ویزیت با موفقیت ثبت شد.', context);
        _resetForm();
      } else if (res.statusCode == 400) {
        final err = jsonDecode(res.body)['error'] ?? 'مشکل در ثبت ویزیت.';
        CustomSnackBar.show(err.toString(), context, isError: true);
      } else if (res.statusCode == 401) {
        CustomSnackBar.show('خطای احراز هویت. لطفاً دوباره وارد شوید.', context, isError: true);
      } else {
        CustomSnackBar.show('خطا (${res.statusCode}).', context, isError: true);
      }
    } catch (e) {
      CustomSnackBar.show('خطا در اتصال: $e', context, isError: true);
    } finally {
      setState(() => _loading = false);
      _loadingAnimCtrl.reset(); // ✅ ریست انیمیشن
    }
  }

/*──────────────────────────── ارسال SOS ─────────────────────────────*/
  Future<void> _sendSOS() async {
    setState(() => _sosLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null || accessToken.isEmpty) {
      CustomSnackBar.show('توکن دسترسی پیدا نشد.', context, isError: true);
      setState(() => _sosLoading = false);
      return;
    }

    try {
      final res = await VisitService.sendSOSVisit(
        visitName: nameController.text.isNotEmpty ? nameController.text : 'اورژانسی',
        description: 'درخواست کمک اورژانسی - ${detailsController.text}',
        accessToken: accessToken,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        CustomSnackBar.show('درخواست اورژانسی ارسال شد. در اسرع وقت با شما تماس خواهیم گرفت.', context);
        _resetForm();
      } else {
        CustomSnackBar.show('خطا در ارسال درخواست اورژانسی.', context, isError: true);
      }
    } catch (e) {
      CustomSnackBar.show('خطا در اتصال: $e', context, isError: true);
    } finally {
      setState(() => _sosLoading = false);
    }
  }

/*──────────────────────────── پزشک آن‌کال ────────────────────────────*/
  Future<void> _toggleDoctorOverlay() async {
    if (_doctorOverlay != null) {
      _removeDoctorOverlay();
      return;
    }
    setState(() => _isDoctorLoading = true);

    try {
      final data = await VisitService.fetchOnCallDoctor();
      if (data == null) {
        _showDoctorOverlay(message: 'پزشکی در دسترس نیست.');
      } else {
        _showDoctorOverlay(
          name     : data['full_name'] ?? '---',
          specialty: data['specialty'] ?? '---',
          imageUrl : data['image']     as String?,
        );
      }
    } catch (_) {
      _showDoctorOverlay(message: 'خطا در اتصال به سرور.');
    } finally {
      setState(() => _isDoctorLoading = false);
    }
  }

  void _showDoctorOverlay({String? name, String? specialty, String? imageUrl, String? message}) {
    final overlay = OverlayEntry(
      builder: (_) => Positioned(
        top  : MediaQuery.of(context).padding.top + 12,
        right: 12,
        child: DoctorDrawer(
          accent   : _primaryColor,
          paleBlue : _paleGreen,
          name     : name,
          specialty: specialty,
          imageUrl : imageUrl,
          message  : message,
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(overlay);
    _doctorOverlay = overlay;

    _overlayTimer?.cancel();
    _overlayTimer = Timer(_autoHideDuration, _removeDoctorOverlay);
  }

  void _removeDoctorOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _doctorOverlay?.remove();
    _doctorOverlay = null;
  }

/*──────────────────────────── انتخاب راه ارتباطی ─────────────────────*/
  void _onContactSelected(String val) {
    setState(() {
      _contactMethod     = val;
      _isContactExpanded = false;
      _contactTileKey    = UniqueKey();
    });
  }

/*──────────────────────────── نسخه‌های قبلی ─────────────────────────*/
  void _showPreviousPrescriptionsPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PreviousPrescriptionsPage()),
    );
    if (result is String && result.isNotEmpty) {
      setState(() {
        detailsController.text = detailsController.text.isNotEmpty
            ? '${detailsController.text}\n\nنسخه داروها:\n$result'
            : 'نسخه داروها:\n$result';
      });
    }
  }

/*──────────────────────────── UI صفحه ───────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundGreen,
        appBar: AppBar(
          title: _buildCloudTitle(),
          centerTitle: true,
          elevation: 0,
          backgroundColor: _backgroundGreen,
          leading: IconButton(
              icon: Icon(Icons.refresh, color: _primaryColor),
              tooltip: 'پزشک کیه؟',
              onPressed: _isDoctorLoading ? null : _toggleDoctorOverlay,
            ),
          iconTheme: IconThemeData(color: _darkGreen),
          actions: [ IconButton(
            icon: Icon(Icons.arrow_circle_left, color: _darkGreen),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
            
          ],
        ),
        body: Stack(
          children: [
            // محتوای اصلی صفحه
            FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ ردیف دکمه‌های دایره ای
                      _circularButtonsRow(),
                      const SizedBox(height: 24),
                      
                      _patientInfoCard(),
                      const SizedBox(height: 20),
                      _descriptionCard(),
                      const SizedBox(height: 20),
                      _contactCard(),
                      const SizedBox(height: 20),
                      _certificateCard(),
                      const SizedBox(height: 24),
                      
                      // ✅ ردیف دکمه‌های اصلی - دایره‌ای شده
                      _mainButtonsRow(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // ✅ پیغام ورودی انیمیشنی
            if (_showWelcomeMessage) _buildWelcomeMessage(),
          ],
        ),
      ),
    );
  }

  // ✅ پیغام ورودی انیمیشنی
  Widget _buildWelcomeMessage() {
    return AnimatedBuilder(
      animation: _welcomeAnimCtrl,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 20,
          right: 20,
          child: Transform.translate(
            offset: Offset(0, _welcomeSlideAnimation.value * 100),
            child: Opacity(
              opacity: _welcomeOpacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor.withOpacity(0.95), _softGreen.withOpacity(0.95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'راهنمای استفاده',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مبلغ ویزیت: ${(_visitCost / 10).toString()} تومان\n\n'
                      'SOS فقط در مواردی استفاده کنید که واقعاً دسترسی به بیمارستان ندارید و می‌دانید نیاز به کمک پزشکی دارید.\n\n'
                      'برای ثبت ویزیت ابتدا اطلاعات بیمار را تکمیل کنید.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _dismissWelcomeMessage(),
                            icon: Icon(Icons.close, size: 18),
                            label: Text('بی خیال'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _dismissWelcomeMessage(dontShowAgain: true),
                            icon: Icon(Icons.visibility_off, size: 18),
                            label: Text('دیگه نمایش نده'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ ردیف دکمه‌های دایره ای
  Widget _circularButtonsRow() => Row(
        children: [
          // دکمه پزشک کیه
          Expanded(
            child: _circularButton(
              onPressed: _isDoctorLoading ? null : _toggleDoctorOverlay,
              color: _primaryColor,
              child: _isDoctorLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_hospital, color: Colors.white, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          _isDoctorLoading ? 'جست‌وجو...' : 'پزشک کیه؟',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // دکمه SOS با انیمیشن چشمک
          Expanded(
            child: AnimatedBuilder(
              animation: _sosAnimation,
              builder: (context, child) {
                return _circularButton(
                  onPressed: _sosLoading ? null : _sendSOS,
                  color: _sosRed.withOpacity(_sosAnimation.value),
                  child: _sosLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning, color: Colors.white, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'SOS!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(_sosAnimation.value),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      );

  // ✅ ردیف دکمه‌های اصلی - دایره‌ای شده
  Widget _mainButtonsRow() => Row(
        children: [
          // دکمه ثبت ویزیت - دایره‌ای
          Expanded(
            flex: 3,
            child: _circularMainButton(
              onPressed: _loading ? null : _sendVisit,
              color: _primaryColor,
              height: 100, // ✅ ارتفاع بیشتر
              child: _loading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // دایره لودینگ
                        AnimatedBuilder(
                          animation: _loadingAnimation,
                          builder: (context, child) {
                            return SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                value: _loadingAnimation.value,
                                strokeWidth: 3,
                                color: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                        // متن
                        const Positioned(
                          bottom: 15,
                          child: Text(
                            'ثبت...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'ثبت ویزیت',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // دکمه ویزیت سریع - دایره‌ای
          Expanded(
            flex: 2,
            child: _circularMainButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialVisitPage()));
              },
              color: _specialGreen,
              height: 100, // ✅ ارتفاع بیشتر
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  const Text(
                    'ویزیت سریع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  // ✅ ویجت دکمه دایره ای کوچک
  Widget _circularButton({
    required VoidCallback? onPressed,
    required Color color,
    required Widget child,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }

  // ✅ ویجت دکمه دایره‌ای اصلی - تغییر شکل به دایره
  Widget _circularMainButton({
    required VoidCallback? onPressed,
    required Color color,
    required Widget child,
    double? height,
  }) {
    final buttonHeight = height ?? 90; // ✅ ارتفاع پیش‌فرض بیشتر
    return Container(
      height: buttonHeight,
      width: buttonHeight, // ✅ عرض برابر ارتفاع برای دایره کامل
      decoration: BoxDecoration(
        shape: BoxShape.circle, // ✅ شکل دایره کامل
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(), // ✅ شکل دایره کامل
          padding: const EdgeInsets.all(20),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }

  // ویجت عنوان ابری
  Widget _buildCloudTitle() {
    return CustomPaint(
      painter: CloudPainter(_primaryColor, _lightGreen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'ثبت ویزیت',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 19,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*────────────────────────  بقیه ویجت‌ها بدون تغییر  ────────────────────*/
  Widget _patientInfoCard() => _cardWrapper(
        'اطلاعات بیمار',
        Icons.person_outline,
        [
          _field(controller: nameController, label: 'نام بیمار', icon: Icons.person),
          const SizedBox(height: 12),
          _field(
            controller: nationalCodeController,
            label     : 'کد ملی',
            icon      : Icons.badge_outlined,
            validator : _validateNationalCode,
          ),
        ],
      );

  Widget _descriptionCard() => _cardWrapper(
        'توضیحات و شرح بیماری',
        Icons.description_outlined,
        [
          _field(
            controller: detailsController,
            label    : 'توضیحات و شرح بیماری',
            icon     : Icons.edit_note,
            maxLines : 4,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value           : _copyPreviousPrescription,
            onChanged       : (value) {
              setState(() => _copyPreviousPrescription = value ?? false);
              if (_copyPreviousPrescription) _showPreviousPrescriptionsPage();
            },
            title           : const Text('میخواهم داروهای مصرفیم را نسخه کنید.',
                style: TextStyle(fontSize: 14)),
            controlAffinity : ListTileControlAffinity.leading,
            contentPadding  : EdgeInsets.zero,
          ),
        ],
      );

  Widget _contactCard() => _cardWrapper(
        'راه ارتباطی',
        Icons.contact_phone_outlined,
        [_contactSelector()],
      );

  Widget _certificateCard() => _cardWrapper(
        'گواهی پزشکی',
        Icons.medical_services_outlined,
        [
          Container(
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _lightGreen.withOpacity(0.3)),
            ),
            child: CheckboxListTile(
              title           : const Text('آیا بیمار نیاز به استعلاجی دارد؟',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              value           : _needsMedicalCertificate,
              onChanged       : (v) =>
                  setState(() => _needsMedicalCertificate = v ?? false),
              controlAffinity : ListTileControlAffinity.leading,
              activeColor     : _primaryColor,
              checkColor      : Colors.white,
              shape           : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );

/*──────────────────────── بقیه ویجت‌های کمکی بدون تغییر ──────────────────*/
  Widget _cardWrapper(String title, IconData icon, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lightGreen.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_primaryColor, _softGreen]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText : label,
          labelStyle: TextStyle(color: _primaryColor.withOpacity(0.8)),
          prefixIcon: Icon(icon, color: _primaryColor),
          border    : OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _lightGreen.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: _paleGreen.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        maxLines : maxLines,
        validator: validator ?? (v) => (v?.isEmpty ?? true) ? 'این فیلد نمی‌تواند خالی باشد' : null,
      );

  String? _validateNationalCode(String? v) {
    if (v == null || v.isEmpty) return 'این فیلد نمی‌تواند خالی باشد';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'کد ملی باید ۱۰ رقم باشد';
    return null;
  }

  Widget _contactSelector() => Container(
        decoration: BoxDecoration(
          color: _paleGreen.withOpacity(0.5),
          border      : Border.all(color: _lightGreen.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: _contactTileKey,
            title: Text('انتخاب راه ارتباطی',
                style: TextStyle(fontWeight: FontWeight.w600, color: _darkGreen)),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.contact_phone, color: Colors.white, size: 16),
            ),
            trailing: Icon(
              _isContactExpanded ? Icons.expand_less : Icons.expand_more,
              color: _primaryColor,
            ),
            initiallyExpanded: _isContactExpanded,
            onExpansionChanged: (expanded) =>
                setState(() => _isContactExpanded = expanded),
            childrenPadding: const EdgeInsets.only(right: 12, left: 12, bottom: 12),
            children: [
              _contactRadio('whatsapp', 'واتس‌اپ', Icons.chat_bubble),
              _contactRadio('bale',     'بله',     Icons.chat),
              _contactRadio('eitaa',    'ایتا',    Icons.forum),
              _contactRadio('phone',    'تلفن',    Icons.phone),
            ],
          ),
        ),
      );

  Widget _contactRadio(String v, String label, IconData icon) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color      : _contactMethod == v ? _primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border      : Border.all(
            color: _contactMethod == v ? _primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: RadioListTile<String>(
          value: v,
          groupValue: _contactMethod,
          onChanged: (val) => _onContactSelected(val!),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _darkGreen)),
          secondary: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _contactMethod == v ? _primaryColor : _lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          activeColor: _primaryColor,
        ),
      );

/*──────────────────────── dispose ──────────────────────*/
  @override
  void dispose() {
    _pageAnimCtrl.dispose();
    _welcomeAnimCtrl.dispose(); // ✅ dispose انیمیشن ورودی
    _sosAnimCtrl.dispose(); // ✅ dispose انیمیشن SOS
    _loadingAnimCtrl.dispose(); // ✅ dispose انیمیشن لودینگ
    _overlayTimer?.cancel();
    _removeDoctorOverlay();
    nameController.dispose();
    nationalCodeController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}

// CloudPainter برای ایجاد شکل ابر (بدون تغییر)
class CloudPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CloudPainter(this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // شکل ابر با منحنی‌های نرم
    path.moveTo(size.width * 0.25, size.height * 0.65);
    
    // دایره کوچک چپ
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.25, size.height * 0.6),
      radius: size.height * 0.25,
    ));
    
    // دایره بزرگ وسط
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.45),
      radius: size.height * 0.35,
    ));
    
    // دایره متوسط راست
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.75, size.height * 0.55),
      radius: size.height * 0.3,
    ));
    
    // دایره کوچک راست
    path.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.85, size.height * 0.7),
      radius: size.height * 0.2,
    ));

    // کف ابر
    path.addRect(Rect.fromLTWH(
      size.width * 0.15, 
      size.height * 0.75, 
      size.width * 0.7, 
      size.height * 0.25
    ));

    canvas.drawPath(path, paint);

    // افکت سایه داخلی
    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2);
    
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}