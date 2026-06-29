import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _queue = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<EmailRepository>();
      final q = await repo.getQueue();
      if (mounted) setState(() {
        _queue = q;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: shadcn.CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _loadQueue,
        child: const Icon(Icons.refresh),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Queue Monitor', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_queue.isEmpty)
              const Text('Queue is empty.')
            else
              Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('Recipient')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Status')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Retries')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Error')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Actions')),
                    ],
                  ),
                  ..._queue.map((item) {
                    final payload = item['payload'] as Map<String, dynamic>?;
                    final recipient = payload?['to'] ?? payload?['user_id'] ?? 'Unknown';
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(recipient)),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['status'])),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['retry_count'].toString())),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['error_message'] ?? '-')),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               if (item['status'] == 'failed' || item['status'] == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 16),
                                    onPressed: () async {
                                      await context.read<EmailRepository>().retryQueueItem(item['id']);
                                      _loadQueue();
                                    },
                                    tooltip: 'Retry',
                                  ),
                               if (item['status'] == 'pending' || item['status'] == 'failed')
                                  IconButton(
                                    icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                    onPressed: () async {
                                      await context.read<EmailRepository>().cancelQueueItem(item['id']);
                                      _loadQueue();
                                    },
                                    tooltip: 'Cancel',
                                  ),
                            ]
                          ),
                        ),
                      ],
                    );
                  })
                ],
              )
          ],
        ),
      ),
    );
  }
}
