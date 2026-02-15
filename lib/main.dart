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

import 'package:finishd_admin/features/users/users_screen.dart';
import 'package:finishd_admin/features/creators/creators_screen.dart';
import 'package:finishd_admin/features/communities/communities_screen.dart';
import 'package:finishd_admin/features/feed/feed_control_screen.dart';
import 'package:finishd_admin/features/analytics/analytics_screen.dart';
import 'package:finishd_admin/features/ml/ml_screen.dart';
import 'package:finishd_admin/features/deeplinks/deeplinks_screen.dart';
import 'package:finishd_admin/features/settings/settings_screen.dart';

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
            final uri = state.uri.toString();

            if (uri.startsWith('/users')) {
              index = 1;
            } else if (uri.startsWith('/creators') || uri.startsWith('/applications')) {
              index = 2;
            } else if (uri.startsWith('/videos')) {
              index = 3;
            } else if (uri.startsWith('/communities')) {
              index = 4;
            } else if (uri.startsWith('/feed')) {
              index = 5;
            } else if (uri.startsWith('/reports')) {
              index = 6;
            } else if (uri.startsWith('/analytics')) {
              index = 8;
            } else if (uri.startsWith('/ml')) {
              index = 9;
            } else if (uri.startsWith('/deeplinks')) {
              index = 10;
            } else if (uri.startsWith('/settings')) {
              index = 11;
            }

            return AdminShell(selectedIndex: index, child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersScreen(),
            ),
            GoRoute(
              path: '/creators',
              builder: (context, state) => const CreatorsScreen(),
            ),
             GoRoute(
              path: '/applications', // Keep this route for now if needed or link it under creators
              builder: (context, state) => const ApplicationsScreen(),
            ),
            GoRoute(
              path: '/videos',
              builder: (context, state) => const VideoReviewScreen(),
            ),
            GoRoute(
              path: '/communities',
              builder: (context, state) => const CommunitiesScreen(),
            ),
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedControlScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/ml',
              builder: (context, state) => const MLScreen(),
            ),
            GoRoute(
              path: '/deeplinks',
              builder: (context, state) => const DeepLinksScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
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
      themeMode: ThemeMode.dark, // Default to dark mode
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
