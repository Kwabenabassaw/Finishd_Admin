import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finishd_admin/core/constants.dart';
import 'package:finishd_admin/core/theme.dart';
import 'package:finishd_admin/features/auth/auth_service.dart';
import 'package:finishd_admin/features/auth/login_screen.dart';
import 'package:finishd_admin/features/dashboard/dashboard_screen.dart';
import 'package:finishd_admin/features/applications/applications_screen.dart';
import 'package:finishd_admin/features/reports/reports_screen.dart';
import 'package:finishd_admin/features/moderation/video_review_screen.dart';
import 'package:finishd_admin/layout/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const FinishdAdminApp(),
    ),
  );
}

class FinishdAdminApp extends StatefulWidget {
  const FinishdAdminApp({super.key});

  @override
  State<FinishdAdminApp> createState() => _FinishdAdminAppState();
}

class _FinishdAdminAppState extends State<FinishdAdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      refreshListenable: context.read<AuthService>(),
      redirect: (context, state) {
        final authService = context.read<AuthService>();
        final isLoggedIn = authService.isAuthenticated;
        final isLoginRoute = state.uri.toString() == '/login';

        if (!isLoggedIn && !isLoginRoute) {
          return '/login';
        }

        if (isLoggedIn && isLoginRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            // Calculate index based on route
            int index = 0;
            if (state.uri.toString().startsWith('/applications')) index = 1;
            if (state.uri.toString().startsWith('/videos')) index = 2;
            if (state.uri.toString().startsWith('/reports')) index = 3;

            return AdminShell(selectedIndex: index, child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/applications',
              builder: (context, state) => const ApplicationsScreen(),
            ),
            GoRoute(
              path: '/videos',
              builder: (context, state) => const VideoReviewScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finishd Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
