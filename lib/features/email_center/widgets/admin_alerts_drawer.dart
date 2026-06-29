import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class AdminAlertsDrawer extends StatefulWidget {
  const AdminAlertsDrawer({super.key});

  @override
  State<AdminAlertsDrawer> createState() => _AdminAlertsDrawerState();
}

class _AdminAlertsDrawerState extends State<AdminAlertsDrawer> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    
    final repo = context.read<EmailRepository>();
    _subscription = repo.subscribeToAlerts(() {
      if (mounted) {
        _loadAlerts(); // reload alerts instead of using payload directly
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new system alert was triggered.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    final repo = context.read<EmailRepository>();
    try {
      final alerts = await repo.getAdminAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id) async {
    final repo = context.read<EmailRepository>();
    try {
      await repo.markAlertAsRead(id);
      setState(() {
        _alerts.removeWhere((a) => a['id'] == id);
      });
    } catch (e) {
      // Error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Admin Alerts',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Expanded(child: Center(child: shadcn.CircularProgressIndicator()))
          else if (_alerts.isEmpty)
            Expanded(
              child: Center(
                child: Text('No active alerts.', style: theme.textTheme.bodyMedium),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  final type = alert['type'] as String;
                  final payload = alert['payload'] as Map<String, dynamic>?;
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: type == 'report' ? Colors.redAccent.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: type == 'report' ? Colors.redAccent.withValues(alpha: 0.3) : theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: type == 'report' ? Colors.redAccent : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, size: 18),
                              onPressed: () => _markRead(alert['id']),
                              tooltip: 'Mark as read',
                              visualDensity: VisualDensity.compact,
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          payload.toString(), // Simplify for now
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
