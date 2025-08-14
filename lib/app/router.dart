import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'seo_meta.dart';

// Common
import '../features/common/widgets/doctor_drawer.dart';
import '../features/common/widgets/particles_background.dart';

// Auth/Profile/Visits
import '../features/auth/presentation/login_page.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/visits/presentation/visit_page.dart';
import '../features/visits/presentation/special_visit_page.dart';
import '../features/visits/presentation/previous_prescriptions_page.dart';

// Contact
import '../contact_info.dart';

// Chat
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/chat/presentation/bloc/chat_cubit.dart';
import '../features/chat/data/session_storage.dart';
import '../features/chat/data/ocr_service.dart';
import '../features/chat/data/pdf_service.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (c, s) {
            SeoMeta.set(
              title: 'هلسا | پزشک آنلاین و گواهی استعلاجی',
              description: 'ویزیت آنلاین، نسخه الکترونیک و پزشک هوش مصنوعی ۲۴ ساعته.',
              path: s.uri.toString(),
            );
            return const NoTransitionPage(child: _Home());
          },
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, s) {
            SeoMeta.set(title: 'ورود | هلسا', description: 'ورود با شماره موبایل و کد تأیید.', path: s.uri.toString());
            return const LoginPage();
          },
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (_, s) {
            SeoMeta.set(title: 'پروفایل | هلسا', description: 'مدیریت حساب و اطلاعات فردی.', path: s.uri.toString());
            return const ProfileScreen();
          },
        ),
        GoRoute(
          path: '/visits',
          name: 'visits',
          builder: (_, s) {
            SeoMeta.set(title: 'ویزیت آنلاین | هلسا', description: 'درخواست و پیگیری ویزیت.', path: s.uri.toString());
            return const VisitPage();
          },
        ),
        GoRoute(
          path: '/visits/special',
          name: 'special_visit',
          builder: (_, s) {
            SeoMeta.set(title: 'ویزیت ویژه | هلسا', description: 'خدمات ویژه‌ی پزشکی.', path: s.uri.toString());
            return const SpecialVisitPage();
          },
        ),
        GoRoute(
          path: '/prescriptions',
          name: 'prescriptions',
          builder: (_, s) {
            SeoMeta.set(title: 'نسخه‌های قبلی | هلسا', description: 'مشاهده نسخه‌های الکترونیک.', path: s.uri.toString());
            return const PreviousPrescriptionsPage();
          },
        ),
        GoRoute(
          path: '/contact',
          name: 'contact',
          builder: (_, s) {
            SeoMeta.set(title: 'تماس با ما | هلسا', description: 'اطلاعات تماس و پشتیبانی.', path: s.uri.toString());
            return const ContactInfoPage();
          },
        ),
      ],
    ),

    // Chat فول‌اسکرین خارج از Shell
    GoRoute(
      path: '/chat/:sessionId',
      name: 'chat',
      pageBuilder: (c, s) {
        final id = s.pathParameters['sessionId'] ?? 'new';
        SeoMeta.set(
          title: 'چت هوشمند | هلسا',
          description: 'ارسال تصویر/PDF، OCR و چت با پزشک هوش مصنوعی.',
          path: s.uri.toString(),
        );
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          child: BlocProvider(
            create: (_) => ChatCubit(SessionStorage(), OcrService(), PdfService())..load(initialSessionId: id),
            child: ChatPage(sessionId: id),
          ),
        );
      },
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('هلسا'),
        actions: [
          IconButton(
            tooltip: 'چت هوشمند',
            onPressed: () => context.go('/chat/new'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      drawer: const DoctorDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: ParticlesBackground()),
          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
        children: [
          FilledButton.icon(onPressed: () => context.go('/chat/new'), icon: const Icon(Icons.chat), label: const Text('شروع چت')),
          OutlinedButton.icon(onPressed: () => context.go('/visits'), icon: const Icon(Icons.calendar_today), label: const Text('ویزیت')),
          OutlinedButton.icon(onPressed: () => context.go('/profile'), icon: const Icon(Icons.person_outline), label: const Text('پروفایل')),
          OutlinedButton.icon(onPressed: () => context.go('/contact'), icon: const Icon(Icons.support_agent), label: const Text('تماس با ما')),
        ],
      ),
    );
  }
}
