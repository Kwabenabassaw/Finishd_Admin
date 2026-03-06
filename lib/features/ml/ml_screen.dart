import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class MLScreen extends StatefulWidget {
  const MLScreen({super.key});

  @override
  State<MLScreen> createState() => _MLScreenState();
}

class _MLScreenState extends State<MLScreen> {
  bool _isComputingRankings = false;
  bool _isComputingTrust = false;

  Future<void> _triggerFeedComputation() async {
    setState(() => _isComputingRankings = true);
    try {
      await context.read<AdminRepository>().deployFeedChanges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed rankings computation triggered')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering feed computation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isComputingRankings = false);
    }
  }

  Future<void> _triggerTrustComputation() async {
    setState(() => _isComputingTrust = true);
    try {
      await context.read<AdminRepository>().computeCreatorTrustScores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trust score computation triggered')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering trust computation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isComputingTrust = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Machine Learning Operations',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MLActionCard(
                  title: 'Compute Feed Rankings',
                  description:
                      'Recalculate video rankings based on latest engagement data (likes, comments, views).',
                  isLoading: _isComputingRankings,
                  onPressed: _triggerFeedComputation,
                  icon: Icons.dynamic_feed,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _MLActionCard(
                  title: 'Compute Trust Scores',
                  description:
                      'Evaluate creator trust scores based on moderation history and community reports.',
                  isLoading: _isComputingTrust,
                  onPressed: _triggerTrustComputation,
                  icon: Icons.verified,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Store Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text('No stats available yet.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MLActionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const _MLActionCard({
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: FilledButton.styleFrom(backgroundColor: color),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(isLoading ? 'Processing...' : 'Run Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
