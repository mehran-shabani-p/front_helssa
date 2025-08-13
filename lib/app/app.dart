import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'router.dart';
import 'theme.dart';

class HelssaApp extends StatelessWidget {
  const HelssaApp({super.key});

  static Future<void> bootstrap() async {
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy(); // وب: URL بدون #
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'هلسا',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
