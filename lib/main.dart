import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finishd_admin/core/constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
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
import 'package:finishd_admin/features/communities/community_members_screen.dart';
import 'package:finishd_admin/features/communities/community_posts_screen.dart';
import 'package:finishd_admin/features/communities/post_comments_screen.dart';
import 'package:finishd_admin/features/feed/feed_control_screen.dart';
import 'package:finishd_admin/features/analytics/analytics_screen.dart';
import 'package:finishd_admin/features/ml/ml_screen.dart';
import 'package:finishd_admin/features/logs/audit_logs_screen.dart';
import 'package:finishd_admin/features/deeplinks/deeplinks_screen.dart';
import 'package:finishd_admin/features/settings/settings_screen.dart';
import 'package:finishd_admin/features/announcements/announcements_screen.dart';
import 'package:finishd_admin/features/user_reports/user_reports_screen.dart';
import 'package:finishd_admin/core/supabase_service.dart';
import 'package:finishd_admin/core/admin_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => SupabaseService()),
        ProxyProvider<SupabaseService, AdminRepository>(
          update: (_, service, __) => AdminRepository(service),
        ),
      ],
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
            } else if (uri.startsWith('/logs')) {
              index = 7; // New index for Audit Logs
            } else if (uri.startsWith('/analytics')) {
              index = 8;
            } else if (uri.startsWith('/ml')) {
              index = 9;
            } else if (uri.startsWith('/deeplinks')) {
              index = 10;
            } else if (uri.startsWith('/settings')) {
              index = 11;
            } else if (uri.startsWith('/announcements')) {
              index = 12;
            } else if (uri.startsWith('/user-reports')) {
              index = 13;
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
              path: '/applications',
              builder: (context, state) => const ApplicationsScreen(),
            ),
            GoRoute(
              path: '/videos',
              builder: (context, state) => const VideoReviewScreen(),
            ),
            GoRoute(
              path: '/communities',
              builder: (context, state) => const CommunitiesScreen(),
              routes: [
                GoRoute(
                  path: ':id/members',
                  builder: (context, state) => CommunityMembersScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/posts',
                  builder: (context, state) => CommunityPostsScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: ':postId/comments',
                      builder: (context, state) => PostCommentsScreen(
                        postId: state.pathParameters['postId']!,
                      ),
                    ),
                  ],
                ),
              ],
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
              path: '/logs',
              builder: (context, state) => const AuditLogsScreen(),
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
              path: '/announcements',
              builder: (context, state) => const AnnouncementsScreen(),
            ),
            GoRoute(
              path: '/user-reports',
              builder: (context, state) => const UserReportsScreen(),
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
    return shadcn.ShadcnApp.router(
      title: 'Finishd Admin',
      theme: shadcn.ThemeData(
        colorScheme: shadcn.ColorSchemes.darkZinc,
        radius: 0.5,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
