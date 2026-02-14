import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final data = await _supabase
          .from('creator_applications')
          .select('*, profiles:user_id(username, avatar_url)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _applications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reviewApplication(
    String id,
    String status, [
    String? notes,
  ]) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('creator_applications')
          .update({
            'status': status,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_notes': notes,
          })
          .eq('id', id);

      // If approved, update the user's role/status in profiles or creator_status
      if (status == 'approved') {
        // Look up the user_id from the application first
        final app = _applications.firstWhere((a) => a['id'] == id);
        final applicantId = app['user_id'];

        await _supabase
            .from('profiles')
            .update({'role': 'creator', 'creator_status': 'approved'})
            .eq('id', applicantId);
      } else if (status == 'rejected') {
        final app = _applications.firstWhere((a) => a['id'] == id);
        final applicantId = app['user_id'];

        await _supabase
            .from('profiles')
            .update({'creator_status': 'rejected'})
            .eq('id', applicantId);
      }

      await _fetchApplications(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $status'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating application: $e')),
        );
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> application) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applicant: ${application['display_name']}'),
            const SizedBox(height: 8),
            Text('Bio: ${application['bio']}'),
            const SizedBox(height: 8),
            const Text('Notes (optional):'),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter review notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewApplication(
                application['id'],
                'rejected',
                notesController.text,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewApplication(
                application['id'],
                'approved',
                notesController.text,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return const Center(child: Text('No pending applications'));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator Applications',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final app = _applications[index];
                final profile = app['profiles'] ?? {};
                final date = DateTime.parse(app['created_at']);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile['avatar_url'] != null
                          ? NetworkImage(profile['avatar_url'])
                          : null,
                      child: profile['avatar_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(app['display_name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${profile['username'] ?? 'unknown'}'),
                        const SizedBox(height: 4),
                        Text(
                          app['bio'] ?? 'No bio provided',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applied on ${DateFormat.yMMMd().format(date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: FilledButton(
                      onPressed: () => _showReviewDialog(app),
                      child: const Text('Review'),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
