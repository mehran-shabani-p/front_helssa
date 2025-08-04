import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// توابع کمکی ـــ اگر ScreenUtil هنوز در دسترس نباشد همان
/// مقدار ثابت (logic-pixels) را برمی‌گردانند.
double _w(double v) {
  try {
    // ‌اگر ScreenUtil مقداردهی شده باشد v.w معتبر است
    return v.w;
  } catch (_) {
    return v;
  }
}

double _r(double v) {
  try {
    return v.r;
  } catch (_) {
    return v;
  }
}

double _sp(double v) {
  try {
    return v.sp;
  } catch (_) {
    return v;
  }
}

class CustomSnackBar {
  /// نمایش Snackbar
  ///
  /// [message]  متن پیام
  /// [isError]  رنگ سبز/قرمز و آیکون را تعیین می‌کند
  static void show(
    String message,
    BuildContext context, {
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_r(10)),
      ),
      margin: EdgeInsets.all(_w(16)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: Colors.white,
            size: _r(20),
          ),
          SizedBox(width: _w(8)),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.vazirmatn(
                fontSize: _sp(14),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    // همیشه قبل از نشان‌دادن، Snackbar قبلی را می‌بندیم
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
