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
      builder: (context, state, child) => EnhancedAppShell(child: child),
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

class EnhancedAppShell extends StatefulWidget {
  final Widget child;
  const EnhancedAppShell({super.key, required this.child});

  @override
  State<EnhancedAppShell> createState() => _EnhancedAppShellState();
}

class _EnhancedAppShellState extends State<EnhancedAppShell> 
    with TickerProviderStateMixin {
  
  late AnimationController _appBarController;
  late AnimationController _fabController;
  late Animation<Offset> _appBarAnimation;
  late Animation<double> _fabAnimation;
  
  bool _isAppBarVisible = true;
  bool _showNavigationPanel = false;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    
    _appBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _appBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _appBarController,
      curve: Curves.easeInOut,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));
    
    _fabController.forward();
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _fabController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _toggleAppBarVisibility(bool visible) {
    if (_isAppBarVisible != visible) {
      setState(() => _isAppBarVisible = visible);
      if (visible) {
        _appBarController.reverse();
      } else {
        _appBarController.forward();
      }
    }
  }

  void _toggleNavigationPanel() {
    setState(() => _showNavigationPanel = !_showNavigationPanel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SlideTransition(
          position: _appBarAnimation,
          child: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('هلسا'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'چت هوشمند',
                onPressed: () => context.go('/chat/new'),
                icon: const Icon(Icons.chat_bubble_outline),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      drawer: const DoctorDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: ParticlesBackground()),
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  final delta = scrollNotification.scrollDelta ?? 0;
                  if (delta > 5) {
                    // Scrolling down - hide app bar
                    _toggleAppBarVisibility(false);
                  } else if (delta < -5) {
                    // Scrolling up - show app bar
                    _toggleAppBarVisibility(true);
                  }
                }
                return false;
              },
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _isAppBarVisible ? kToolbarHeight : 0,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Buttons
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation Panel FAB
            FloatingActionButton.small(
              heroTag: "navigation",
              onPressed: _toggleNavigationPanel,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              child: AnimatedRotation(
                turns: _showNavigationPanel ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.menu),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Chat FAB
            FloatingActionButton(
              heroTag: "chat",
              onPressed: () => context.go('/chat/new'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.chat_bubble),
            ),
          ],
        ),
      ),
      
      // Navigation Panel Overlay
      if (_showNavigationPanel)
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showNavigationPanel = false),
            child: Container(
              color: Colors.black54,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _fabController,
                      curve: Curves.easeInOut,
                    )),
                    child: Material(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: double.infinity,
                        child: _QuickNavigationPanel(
                          onNavigate: () => setState(() => _showNavigationPanel = false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _QuickNavigationPanel extends StatelessWidget {
  final VoidCallback onNavigate;
  
  const _QuickNavigationPanel({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هلسا',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'کلینیک هوشمند',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Actions
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دسترسی سریع',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: ListView(
                        children: [
                          _buildNavigationTile(
                            context,
                            icon: Icons.home_outlined,
                            title: 'خانه',
                            subtitle: 'صفحه اصلی',
                            onTap: () {
                              onNavigate();
                              context.go('/');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.chat_bubble_outline,
                            title: 'چت هوشمند',
                            subtitle: 'گفتگو با پزشک هوش مصنوعی',
                            onTap: () {
                              onNavigate();
                              context.go('/chat/new');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.person_outline,
                            title: 'پروفایل',
                            subtitle: 'مدیریت حساب کاربری',
                            onTap: () {
                              onNavigate();
                              context.go('/profile');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.calendar_today,
                            title: 'ویزیت آنلاین',
                            subtitle: 'درخواست ویزیت پزشک',
                            onTap: () {
                              onNavigate();
                              context.go('/visits');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.star_border,
                            title: 'ویزیت ویژه',
                            subtitle: 'خدمات پزشکی ویژه',
                            onTap: () {
                              onNavigate();
                              context.go('/visits/special');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.receipt_long,
                            title: 'نسخه‌های قبلی',
                            subtitle: 'مشاهده نسخه‌های الکترونیک',
                            onTap: () {
                              onNavigate();
                              context.go('/prescriptions');
                            },
                          ),
                          _buildNavigationTile(
                            context,
                            icon: Icons.support_agent,
                            title: 'تماس با ما',
                            subtitle: 'پشتیبانی و راهنمایی',
                            onTap: () {
                              onNavigate();
                              context.go('/contact');
                            },
                          ),
                        ],
                      ),
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

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'به هلسا خوش آمدید',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'کلینیک هوشمند شما',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionCard(
                context,
                icon: Icons.chat_bubble,
                title: 'شروع چت',
                subtitle: 'پزشک هوش مصنوعی',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.go('/chat/new'),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'ویزیت آنلاین',
                subtitle: 'نوبت دهی آنلاین',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => context.go('/visits'),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.person_outline,
                title: 'پروفایل',
                subtitle: 'مدیریت حساب',
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => context.go('/profile'),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.support_agent,
                title: 'تماس با ما',
                subtitle: 'پشتیبانی',
                color: Colors.orange,
                onTap: () => context.go('/contact'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
