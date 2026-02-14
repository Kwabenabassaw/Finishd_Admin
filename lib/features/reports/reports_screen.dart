import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final data = await _supabase
          .from('creator_video_reports')
          .select('*, video:video_id(*), reporter:reporter_id(username)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data);
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

  Future<void> _handleReport(String id, String status, [String? notes]) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('creator_video_reports')
          .update({
            'status': status,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_notes': notes,
          })
          .eq('id', id);

      // If status is 'resolved' (meaning content was indeed bad), we might want to take action on the video
      if (status == 'resolved') {
        // Find the video ID
        final report = _reports.firstWhere((r) => r['id'] == id);
        final videoId = report['video_id'];

        // For now, let's just mark the video as 'moderated' or 'removed'
        // Assuming there is a status column on creator_videos
        await _supabase
            .from('creator_videos')
            .update({
              'status': 'removed', // or 'moderated'
            })
            .eq('id', videoId);
      }

      await _fetchReports();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating report: $e')));
      }
    }
  }

  void _showActionDialog(Map<String, dynamic> report) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: ${report['reason']}'),
            if (report['details'] != null) ...[
              const SizedBox(height: 8),
              Text('Details: ${report['details']}'),
            ],
            const SizedBox(height: 16),
            const Text('Action Notes:'),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter internal notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              _handleReport(report['id'], 'dismissed', notesController.text);
            },
            child: const Text('Dismiss Report'), // False alarm
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _handleReport(report['id'], 'resolved', notesController.text);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove Content'), // Valid report
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

    if (_reports.isEmpty) {
      return const Center(child: Text('No pending reports'));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Reports',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final report = _reports[index];
                final reporter = report['reporter'] ?? {};
                final video = report['video'] ?? {};
                final date = DateTime.parse(report['created_at']);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.video_library, size: 32),
                    title: Text('Report on "${video['title'] ?? 'Video'}"'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reason: ${report['reason']}'),
                        Text(
                          'Reported by @${reporter['username'] ?? 'unknown'} on ${DateFormat.yMMMd().format(date)}',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => _showActionDialog(report),
                      child: const Text('Take Action'),
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
