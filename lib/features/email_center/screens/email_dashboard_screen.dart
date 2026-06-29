import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class EmailDashboardScreen extends StatefulWidget {
  const EmailDashboardScreen({super.key});

  @override
  State<EmailDashboardScreen> createState() => _EmailDashboardScreenState();
}

class _EmailDashboardScreenState extends State<EmailDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<EmailRepository>();
      final stats = await repo.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading stats: $e')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: shadcn.CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('System Overview', style: Theme.of(context).textTheme.titleLarge),
               IconButton(
                 icon: const Icon(Icons.refresh),
                 onPressed: _loadStats,
               )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Sent',
                  value: _stats['total_sent']?.toString() ?? '0',
                  icon: Icons.mark_email_read_outlined,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Pending in Queue',
                  value: _stats['queue_size']?.toString() ?? '0',
                  icon: Icons.hourglass_empty,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Failed',
                  value: _stats['failed']?.toString() ?? '0',
                  icon: Icons.error_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          // Additional charts can be added here
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
