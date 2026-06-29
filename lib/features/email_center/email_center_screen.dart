import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:finishd_admin/features/email_center/screens/email_dashboard_screen.dart';
import 'package:finishd_admin/features/email_center/screens/compose_email_screen.dart';
import 'package:finishd_admin/features/email_center/screens/template_manager_screen.dart';
import 'package:finishd_admin/features/email_center/screens/email_history_screen.dart';
import 'package:finishd_admin/features/email_center/screens/queue_monitor_screen.dart';
import 'package:finishd_admin/features/email_center/widgets/admin_alerts_drawer.dart';

class EmailCenterScreen extends StatefulWidget {
  const EmailCenterScreen({super.key});

  @override
  State<EmailCenterScreen> createState() => _EmailCenterScreenState();
}

class _EmailCenterScreenState extends State<EmailCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: const Drawer(
        width: 400,
        child: AdminAlertsDrawer(),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                EmailDashboardScreen(),
                ComposeEmailScreen(),
                TemplateManagerScreen(),
                QueueMonitorScreen(),
                EmailHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Email Center',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              shadcn.OutlineButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Admin Alerts'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Compose'),
              Tab(text: 'Templates'),
              Tab(text: 'Queue Monitor'),
              Tab(text: 'History'),
            ],
          ),
        ],
      ),
    );
  }
}
