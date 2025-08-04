// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '/screens/visit/visit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:async';

// 50‑item health guidelines list
import '/screens/visit/guidelines.dart';

// --- رنگ‌های سبز ---
class SpecialVisitColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

class SpecialVisitPage extends StatefulWidget {
  const SpecialVisitPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SpecialVisitPageState createState() => _SpecialVisitPageState();
}

class _SpecialVisitPageState extends State<SpecialVisitPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> specialVisits = [
    {
      'name': 'سردرد',
      'description': 'بررسی انواع سردرد و میگرن',
      'icon': Icons.psychology,
      'color': SpecialVisitColors.primaryGreen,
    },
    {
      'name': 'سرماخوردگی',
      'description': 'علائم تب، سرفه و آبریزش بینی',
      'icon': Icons.sick,
      'color': SpecialVisitColors.lightGreen,
    },
    {
      'name': 'اسهال و استفراغ',
      'description': 'مشکلات گوارشی و درمان',
      'icon': Icons.medical_services,
      'color': SpecialVisitColors.darkGreen,
    },
    {
      'name': 'دل درد',
      'description': 'دلایل مختلف شکمی',
      'icon': Icons.restaurant,
      'color': SpecialVisitColors.softGreen,
    },
  ];

  final List<Map<String, dynamic>> healthGuidelines = guidelines;

  late AnimationController _loadingController;
  late AnimationController _pulseController;
  late AnimationController _circularController;
  late PageController _pageController;
  late Timer _autoSlideTimer;

  // ✅ انیمیشن پیغام ورودی
  late AnimationController _welcomeAnimCtrl;
  late Animation<double> _welcomeSlideAnimation;
  late Animation<double> _welcomeOpacityAnimation;

  bool _loading = false;
  int? _pressedIndex;
  bool _showWelcomeMessage = true; // ✅ نمایش پیغام ورودی
  bool _dontShowAgain = false; // ✅ دیگه نمایش نده
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _circularController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    
    // ✅ انیمیشن پیغام ورودی
    _welcomeAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _welcomeSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeOutBack)
    );
    _welcomeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeInOut)
    );
    
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoSlide();
    _loadPreferences(); // ✅ بارگذاری تنظیمات
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentSlideIndex + 1) % healthGuidelines.length;
        _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      }
    });
  }

  // ✅ بارگذاری تنظیمات ذخیره شده
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool('dont_show_special_visit_info') ?? false;
    
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
    await prefs.setBool('dont_show_special_visit_info', _dontShowAgain);
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

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    _circularController.dispose();
    _welcomeAnimCtrl.dispose(); // ✅ dispose انیمیشن ورودی
    _pageController.dispose();
    _autoSlideTimer.cancel();
    super.dispose();
  }

  Future<void> _createSpecialVisit(String visitName, String description) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null) {
        _showCustomSnackBar('توکن دسترسی پیدا نشد.', isError: true);
        return;
      }
      final request = http.MultipartRequest('POST', Uri.parse('https://api.medogram.ir/api/super-visit/250000/'))
        ..headers.addAll({'Authorization': 'Bearer $accessToken'})
        ..fields.addAll({
          'name': visitName,
          'urgency': 'prescription',
          'general_symptoms': 'fever',
          'description': description,
        });
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showCustomSnackBar('ویزیت با موفقیت ثبت شد.');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VisitPage()));
      } else {
        _showCustomSnackBar('خطا در ثبت ویزیت. لطفاً وضعیت احراز هویت و کیف پول را بررسی کنید.', isError: true);
      }
    } catch (_) {
      _showCustomSnackBar('خطا در اتصال به سرور', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _pressedIndex = null;
        });
        _circularController.reset();
      }
    }
  }

  void _handleLongPress(int index, String visitName, String description) {
    HapticFeedback.mediumImpact();
    setState(() => _pressedIndex = index);
    _circularController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (_pressedIndex == index) {
        HapticFeedback.heavyImpact();
        _createSpecialVisit(visitName, description);
      }
    });
  }

  void _handleLongPressEnd() {
    if (_pressedIndex != null) {
      setState(() => _pressedIndex = null);
      _circularController.reset();
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white), SizedBox(width: 8.w), Expanded(child: Text(message, style: GoogleFonts.vazirmatn(fontSize: 13.sp)))]),
        backgroundColor: isError ? Colors.red : SpecialVisitColors.lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  //----------------‑ UI BUILDERS ----------------

  Widget _buildHeader() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [SpecialVisitColors.primaryGreen, SpecialVisitColors.softGreen], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 14.h),
          child: Column(children: [
            const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
            SizedBox(height: 6.h),
            Text('ویزیت‌های شایع', style: GoogleFonts.vazirmatn(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 4.h),
            Text('برای ثبت ویزیت، روی دایره نگه دارید', style: GoogleFonts.vazirmatn(fontSize: 12.sp, color: Colors.white70)),
          ]),
        ),
      );

  // ✅ پیغام ورودی انیمیشنی
  Widget _buildWelcomeMessage() {
    return AnimatedBuilder(
      animation: _welcomeAnimCtrl,
      builder: (context, child) {
        return Positioned(
          top: 80.h,
          left: 20.w,
          right: 20.w,
          child: Transform.translate(
            offset: Offset(0, _welcomeSlideAnimation.value * 100),
            child: Opacity(
              opacity: _welcomeOpacityAnimation.value,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SpecialVisitColors.primaryGreen.withOpacity(0.95), SpecialVisitColors.softGreen.withOpacity(0.95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: SpecialVisitColors.primaryGreen.withOpacity(0.3),
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
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.white, size: 24.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'راهنمای ویزیت سریع',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'قیمت ویزیت سریع: 25,000 تومان\n\n'
                      'برای ثبت ویزیت، روی دایره مورد نظر نگه دارید تا کامل شود.\n\n'
                      'این ویزیت‌ها برای بیماری‌های شایع و ساده طراحی شده‌اند.',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _dismissWelcomeMessage(),
                            icon: Icon(Icons.close, size: 18.sp),
                            label: Text('بی خیال', style: GoogleFonts.vazirmatn()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _dismissWelcomeMessage(dontShowAgain: true),
                            icon: Icon(Icons.visibility_off, size: 18.sp),
                            label: Text('دیگه نمایش نده', style: GoogleFonts.vazirmatn()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: SpecialVisitColors.primaryGreen,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
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

  Widget _buildGuidelinesSlider() {
  final double sliderHeight = ScreenUtil().screenHeight * 0.35; // کمی بیشتر برای طراحی جدید
  
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    child: Column(
      children: [
        // ✅ Header بهبود یافته
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SpecialVisitColors.primaryGreen.withOpacity(0.1),
                SpecialVisitColors.softGreen.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: SpecialVisitColors.primaryGreen.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SpecialVisitColors.primaryGreen,
                      SpecialVisitColors.lightGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: SpecialVisitColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'راهنمای سلامت',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: SpecialVisitColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'نکات مفید برای سلامتی شما',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.sp,
                        color: SpecialVisitColors.darkGreen.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Progress indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: SpecialVisitColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_currentSlideIndex + 1}/${healthGuidelines.length}',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: SpecialVisitColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // ✅ Slider مدرن
        SizedBox(
          height: sliderHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentSlideIndex = i),
            itemCount: healthGuidelines.length,
            itemBuilder: (ctx, i) {
              final g = healthGuidelines[i];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - i;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * sliderHeight,
                      width: Curves.easeOut.transform(value) * 320.w,
                      child: child,
                    ),
                  );
                },
                child: _buildModernGuidelineCard(g, i),
              );
            },
          ),
        ),
        
        SizedBox(height: 20.h),
        
        // ✅ Modern Page Indicator
        _buildModernPageIndicator(),
      ],
    ),
  );
}

// ✅ کارت مدرن راهنما
Widget _buildModernGuidelineCard(Map<String, dynamic> g, int index) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 8.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24.r),
      boxShadow: [
        BoxShadow(
          color: g['color'].withOpacity(0.15),
          blurRadius: 20,
          offset: Offset(0, 10),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.9),
          blurRadius: 1,
          offset: Offset(0, 1),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            g['color'].withOpacity(0.02),
            g['color'].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: g['color'].withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // ✅ Background Pattern
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: g['color'].withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: g['color'].withOpacity(0.02),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // ✅ Main Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Header با آیکون
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            g['color'],
                            g['color'].withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: g['color'].withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        g['icon'],
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['title'],
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: SpecialVisitColors.darkGreen,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 3.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  g['color'],
                                  g['color'].withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),
                
                // Content Area
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: g['color'].withOpacity(0.1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        g['content'],
                        style: GoogleFonts.vazirmatn(
                          fontSize: 13.sp,
                          height: 1.6,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // ✅ Bottom Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: g['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 14.sp,
                            color: g['color'],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'نکته سلامت',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11.sp,
                              color: g['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: g['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.bookmark_border,
                        size: 16.sp,
                        color: g['color'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ✅ Modern Page Indicator
Widget _buildModernPageIndicator() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25.r),
      boxShadow: [
        BoxShadow(
          color: SpecialVisitColors.primaryGreen.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Navigation Buttons
        GestureDetector(
          onTap: () {
            if (_currentSlideIndex > 0) {
              _pageController.animateToPage(
                _currentSlideIndex - 1,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _currentSlideIndex > 0 
                ? SpecialVisitColors.primaryGreen
                : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.chevron_left,
              color: _currentSlideIndex > 0 ? Colors.white : Colors.grey,
              size: 16.sp,
            ),
          ),
        ),
        
        SizedBox(width: 16.w),
        
        // ✅ Dots Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            math.min(healthGuidelines.length, 7), // حداکثر 7 نقطه نمایش
            (i) {
              int actualIndex;
              if (healthGuidelines.length <= 7) {
                actualIndex = i;
              } else {
                // محاسبه نمایش برای لیست طولانی
                if (_currentSlideIndex <= 3) {
                  actualIndex = i;
                } else if (_currentSlideIndex >= healthGuidelines.length - 4) {
                  actualIndex = healthGuidelines.length - 7 + i;
                } else {
                  actualIndex = _currentSlideIndex - 3 + i;
                }
              }
              
              bool isActive = actualIndex == _currentSlideIndex;
              bool isCenter = i == 3 && healthGuidelines.length > 7;
              
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: isActive ? 24.w : isCenter ? 16.w : 8.w,
                height: isActive ? 8.h : 6.h,
                decoration: BoxDecoration(
                  color: isActive 
                    ? SpecialVisitColors.primaryGreen
                    : SpecialVisitColors.primaryGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              );
            },
          ),
        ),
        
        SizedBox(width: 16.w),
        
        // ✅ Next Button
        GestureDetector(
          onTap: () {
            if (_currentSlideIndex < healthGuidelines.length - 1) {
              _pageController.animateToPage(
                _currentSlideIndex + 1,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _currentSlideIndex < healthGuidelines.length - 1
                ? SpecialVisitColors.primaryGreen
                : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.chevron_right,
              color: _currentSlideIndex < healthGuidelines.length - 1 
                ? Colors.white 
                : Colors.grey,
              size: 16.sp,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: SpecialVisitColors.backgroundGreen,
          appBar: AppBar(centerTitle: true, backgroundColor: SpecialVisitColors.primaryGreen, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
          body: _loading
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Lottie.asset('assets/loading.json', width: 120.w, height: 120.w), SizedBox(height: 6.h), Text('در حال ثبت ویزیت...', style: GoogleFonts.vazirmatn(fontSize: 13.sp, fontWeight: FontWeight.w500, color: SpecialVisitColors.primaryGreen))]))
              : Stack( // ✅ تغییر از SingleChildScrollView به Stack
                  children: [
                    // محتوای اصلی صفحه
                    SingleChildScrollView(child: Column(children: [_buildHeader(), _buildVisitGrid(), _buildGuidelinesSlider(), SizedBox(height: 16.h)])),
                    
                    // ✅ پیغام ورودی انیمیشنی
                    if (_showWelcomeMessage) _buildWelcomeMessage(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVisitGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 6.w, mainAxisSpacing: 6.h, childAspectRatio: 0.8),
        itemCount: specialVisits.length,
        itemBuilder: (ctx, i) {
          final v = specialVisits[i];
          final pressed = _pressedIndex == i;
          return Animate(
            effects: [FadeEffect(duration: Duration(milliseconds: 300 + (i * 100))), ScaleEffect(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: Duration(milliseconds: 300 + (i * 100)))],
            child: _buildCircularVisitCard(v, i, pressed),
          );
        },
      );

  Widget _buildCircularVisitCard(Map<String, dynamic> v, int i, bool pressed) {
    return GestureDetector(
      onLongPressStart: (_) => _handleLongPress(i, v['name'], v['description']),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), boxShadow: [BoxShadow(color: pressed ? v['color'].withOpacity(0.3) : SpecialVisitColors.primaryGreen.withOpacity(0.07), blurRadius: pressed ? 12 : 6, offset: const Offset(0, 2))]),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: Listenable.merge([_circularController, _pulseController]),
              builder: (_, _) => Stack(alignment: Alignment.center, children: [
                Container(width: 52.w, height: 52.w, decoration: BoxDecoration(shape: BoxShape.circle, color: v['color'].withOpacity(0.1), border: Border.all(color: v['color'].withOpacity(0.3), width: 2))),
                if (pressed)
                  SizedBox(
                    width: 60.w,
                    height: 60.w,
                    child: Transform.rotate(angle: _circularController.value * 2 * math.pi, child: CustomPaint(painter: _CircularProgressPainter(progress: _circularController.value, color: v['color']))),
                  ),
                Icon(v['icon'], size: pressed ? 26.sp : 22.sp, color: pressed ? v['color'] : v['color'].withOpacity(0.9)),
              ]),
            ),
            SizedBox(height: 6.h),
            Text(v['name'], textAlign: TextAlign.center, style: GoogleFonts.vazirmatn(fontSize: 13.sp, fontWeight: FontWeight.bold, color: pressed ? v['color'] : SpecialVisitColors.darkGreen)),
            SizedBox(height: 4.h),
            Text(v['description'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.vazirmatn(fontSize: 12.sp, color: pressed ? v['color'].withOpacity(0.8) : Colors.grey[600], height: 1.2)),
            if (pressed) ...[SizedBox(height: 4.h), Text('${(_circularController.value * 100).toInt()}%', style: GoogleFonts.vazirmatn(fontSize: 12.sp, fontWeight: FontWeight.bold, color: v['color']))],
          ]),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CircularProgressPainter({required this.progress, required this.color});
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final radius = (s.width - 4) / 2;
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, progress * 2 * math.pi, false, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}