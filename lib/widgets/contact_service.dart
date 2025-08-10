import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

// --- رنگ‌های سبز ---
class ContactColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

class ContactService {
  
  
  /* ============================================================================
  تابع دانلود APK اندروید با Loading State
  ===========================================================================*/
  
  static Future<void> downloadAndroidApk(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // چک کردن پلتفرم - فقط برای موبایل
    if (kIsWeb) {
      _showErrorSnackBar(scaffoldMessenger, 'دانلود APK فقط در دستگاه‌های موبایل قابل دسترس است.');
      return;
    }

    // نمایش Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ContactColors.primaryGreen),
                ),
                const SizedBox(height: 16),
                const Text('در حال آماده‌سازی دانلود...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/download-apk'),
        headers: {
          'User-Agent': 'HELSSA-Mobile-App',
        },
      ).timeout(const Duration(seconds: 10));

      // بستن Loading Dialog
      if (navigator.canPop()) navigator.pop();

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.download, color: Colors.white),
                SizedBox(width: 8),
                Text('دانلود آغاز شد.'),
              ],
            ),
            backgroundColor: ContactColors.lightGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        await launchUrl(
          Uri.parse('$baseUrl/api/download-apk'),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar(scaffoldMessenger, 'دانلود با خطا مواجه شد. لطفاً دوباره تلاش کنید.');
      }
    } catch (e) {
      if (navigator.canPop()) navigator.pop(); // بستن Loading Dialog
      _showErrorSnackBar(scaffoldMessenger, 'خطا در اتصال به سرور.');
    }
  }

  /* ============================================================================
  تابع لانچ URL با پشتیبانی از وب و موبایل
  ===========================================================================*/
  
  static Future<bool> launchContactUrl(String url, {LaunchMode? mode}) async {
    try {
      final uri = Uri.parse(url);
      
      // برای وب، از mode متفاوت استفاده می‌کنیم
      final launchMode = kIsWeb 
          ? LaunchMode.platformDefault 
          : (mode ?? LaunchMode.externalApplication);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: launchMode);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  /* ============================================================================
  Helper Functions
  ===========================================================================*/
  
  static void _showErrorSnackBar(ScaffoldMessengerState scaffoldMessenger, String message) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: ContactColors.lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /* ============================================================================
  اطلاعات تماس به صورت استاتیک
  ===========================================================================*/
  
  static const List<Map<String, dynamic>> contactMethods = [
    {
      'icon': 'material.email_rounded',
      'title': 'ایمیل',
      'subtitle': 'پاسخ تا ۲۴ ساعت',
      'content': 'info@medogram.ir',
      'url': 'mailto:info@medogram.ir',
      'color': ContactColors.lightGreen,
      'isExternal': true,
    },
    {
      'icon': 'fontawesome.instagram',
      'title': 'اینستاگرام',
      'subtitle': 'صفحه رسمی ما',
      'content': '@medogram.online',
      'url': 'https://instagram.com/medogram.online',
      'color': ContactColors.primaryGreen,
      'isExternal': true,
    },
    {
      'icon': 'fontawesome.telegram',
      'title': 'کانال تلگرام',
      'subtitle': 'کانال سلامتی و ویزیت آنلاین',
      'content': '@medogramiran',
      'url': 'https://t.me/medogramiran',
      'color': ContactColors.darkGreen,
      'isExternal': true,
    },
    {
      'icon': 'fontawesome.whatsapp',
      'title': 'واتساپ',
      'subtitle': 'پشتیبانی آنلاین',
      'content': '+989961733668',
      'url': 'https://wa.me/989961733668',
      'color': ContactColors.softGreen,
      'isExternal': true,
    },
    {
      'icon': 'material.sms_rounded',
      'title': 'پیامک',
      'subtitle': 'ارسال پیام کوتاه',
      'content': '+989961733668',
      'url': 'sms:+989961733668',
      'color': ContactColors.lightGreen,
      'isExternal': false, // فقط موبایل
    },
    {
      'icon': 'fontawesome.paperPlane',
      'title': 'ایتا',
      'subtitle': 'پیام‌رسان داخلی',
      'content': '@mehratena2318',
      'url': 'https://eitaa.com/mehratena2318',
      'color': ContactColors.primaryGreen,
      'isExternal': true,
    },
  ];

  /* ============================================================================
  اطلاعات Drawer Sections
  ===========================================================================*/
  
  static List<Map<String, dynamic>> getDrawerSections(BuildContext context) {
    return [
      {
        'title': 'خدمات',
        'items': [
          {
            'icon': Icons.medical_services_outlined,
            'title': 'ویزیت آنلاین',
            'subtitle': 'مشاوره با پزشک',
            'onTap': () => Navigator.pop(context),
          },
          {
            'icon': Icons.chat_bubble_outline,
            'title': 'چت با هوش مصنوعی',
            'subtitle': 'پاسخ فوری به سوالات',
            'onTap': () => Navigator.pop(context),
          },
          {
            'icon': Icons.history,
            'title': 'تاریخچه ویزیت',
            'subtitle': 'مشاهده نسخه‌های قبلی',
            'onTap': () => Navigator.pop(context),
          },
        ],
      },
      {
        'title': 'اطلاعات',
        'items': [
          {
            'icon': Icons.gavel_rounded,
            'title': 'شرایط و قوانین',
            'subtitle': 'قوانین استفاده از خدمات',
            'onTap': () => showTermsDialog(context),
          },
          {
            'icon': Icons.privacy_tip_outlined,
            'title': 'حریم خصوصی',
            'subtitle': 'سیاست حفظ اطلاعات',
            'onTap': () => showPrivacyDialog(context),
          },
          {
            'icon': Icons.help_outline,
            'title': 'راهنما',
            'subtitle': 'آموزش استفاده از اپ',
            'onTap': () => showHelpDialog(context),
          },
        ],
      },
      {
        'title': 'دانلود',
        'items': [
          {
            'icon': Icons.android_rounded,
            'title': 'نسخه اندروید',
            'subtitle': 'دانلود APK',
            'onTap': () => downloadAndroidApk(context),
          },
          {
            'icon': Icons.system_update,
            'title': 'به‌روزرسانی',
            'subtitle': 'آخرین نسخه موجود',
            'onTap': () => showUpdateInfo(context),
          },
        ],
      },
    ];
  }

  /* ============================================================================
  Dialog Functions
  ===========================================================================*/
  
  static void showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: ContactColors.primaryGreen),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'شرایط و قوانین خدمات',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'خدمات زیر تحت پوشش نیستند:',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: ContactColors.darkGreen,
                ),
              ),
              const SizedBox(height: 12),
              ...const [
                'مدیریت اورژانس‌های تهدیدکننده زندگی',
                'انتقال و حمل فیزیکی بیماران',
                'خدمات پزشکی در محل حادثه',
                'مداخلات جراحی اورژانسی',
                'تجویز فوری داروهای نجات‌بخش',
                'تثبیت شرایط بحرانی',
                'معاینات فیزیکی حضوری',
              ].map((text) => _TermItem(text: text)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: ContactColors.paleGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'بستن',
              style: TextStyle(color: ContactColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: ContactColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('حریم خصوصی'),
          ],
        ),
        content: Text(
          'تمامی اطلاعات شما با بالاترین سطح امنیت محافظت می‌شود و هیچ‌گاه با اشخاص ثالث به اشتراک گذاشته نمی‌شود.',
          style: TextStyle(color: ContactColors.darkGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: ContactColors.paleGreen,
            ),
            child: Text(
              'متوجه شدم',
              style: TextStyle(color: ContactColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: ContactColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('راهنمای استفاده'),
          ],
        ),
        content: Text(
          '۱. برای ویزیت آنلاین، از منوی اصلی "ثبت ویزیت" را انتخاب کنید\n'
          '۲. اطلاعات خود را کامل وارد کنید\n'
          '۳. منتظر پاسخ پزشک باشید\n'
          '۴. برای سوالات فوری از چت هوش مصنوعی استفاده کنید',
          style: TextStyle(color: ContactColors.darkGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: ContactColors.paleGreen,
            ),
            child: Text(
              'متوجه شدم',
              style: TextStyle(color: ContactColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showUpdateInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: ContactColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('به‌روزرسانی'),
          ],
        ),
        content: Text(
          'شما از نسخه $currentVersion استفاده می‌کنید.\n'
          'دانلود نسخه جدید به صورت خودکار انجام می شود.',
          style: TextStyle(color: ContactColors.darkGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: ContactColors.paleGreen,
            ),
            child: Text(
              'باشه',
              style: TextStyle(color: ContactColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String text;

  const _TermItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ContactColors.primaryGreen,
          )),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/* ============================================================================
WebViewPage فقط برای موبایل
===========================================================================*/

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, required this.title});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool isLoading = true;
  late final dynamic controller; // WebViewController فقط در موبایل

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // فقط در موبایل WebView را مقداردهی می‌کنیم
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    // این کد فقط در موبایل اجرا می‌شود
    // controller = WebViewController()
    //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //   ..setNavigationDelegate(
    //     NavigationDelegate(
    //       onPageStarted: (_) => setState(() => isLoading = true),
    //       onPageFinished: (_) => setState(() => isLoading = false),
    //     ),
    //   )
    //   ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // در وب، صفحه خطا نمایش می‌دهیم
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: ContactColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('WebView در وب پشتیبانی نمی‌شود'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: ContactColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // WebViewWidget(controller: controller), // فقط در موبایل
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ContactColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}