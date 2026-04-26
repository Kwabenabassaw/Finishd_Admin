import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/supabase_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'announcement';
  bool _isSending = false;

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Broadcast?'),
        content: const Text(
          'This will send a push notification to ALL registered users. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send to Everyone'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      final service = context.read<SupabaseService>();
      
      await service.broadcastAnnouncement(
        title: _titleController.text,
        body: _bodyController.text,
        type: _type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent successfully!')),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending broadcast: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Announcements',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a push notification to all users across the platform.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notification Content', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                hintText: 'e.g., New Feature Released!',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bodyController,
                              decoration: const InputDecoration(
                                labelText: 'Message Body',
                                hintText: 'Describe the announcement...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _type,
                              decoration: const InputDecoration(
                                labelText: 'Notification Type',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'announcement', child: Text('Standard Announcement')),
                                DropdownMenuItem(value: 'alert', child: Text('Urgent Alert')),
                                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance Update')),
                              ],
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isSending ? null : _sendBroadcast,
                                icon: _isSending 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send_rounded),
                                label: Text(_isSending ? 'Sending...' : 'Broadcast Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Preview Section
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notifications_active, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('FINISHD • NOW', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _titleController.text.isEmpty ? 'Notification Title' : _titleController.text,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _bodyController.text.isEmpty ? 'Your message will appear here...' : _bodyController.text,
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Delivery Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.people_outline, color: Colors.green),
                          title: Text('Reachable Users'),
                          subtitle: Text('~1,250 devices active'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
