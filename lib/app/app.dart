import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/profile/data/profile_service.dart';
import '../features/profile/presentation/bloc/profile_cubit.dart';
import '../features/visits/data/visit_service.dart';
import '../features/visits/presentation/bloc/visits_cubit.dart';
import '../features/visits/presentation/bloc/prescriptions_cubit.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(AuthService())),
        BlocProvider(create: (_) => ProfileCubit(ProfileService())),
        BlocProvider(create: (_) => VisitsCubit(VisitService())),
        BlocProvider(create: (_) => PrescriptionsCubit(VisitService())),
      ],
      child: MaterialApp.router(
        title: 'هلسا',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}
