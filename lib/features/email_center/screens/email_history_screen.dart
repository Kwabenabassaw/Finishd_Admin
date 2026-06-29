import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class EmailHistoryScreen extends StatefulWidget {
  const EmailHistoryScreen({super.key});

  @override
  State<EmailHistoryScreen> createState() => _EmailHistoryScreenState();
}

class _EmailHistoryScreenState extends State<EmailHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<EmailRepository>();
      final hist = await repo.getHistory(page: _page);
      if (mounted) setState(() {
        _history = hist;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Email History', style: Theme.of(context).textTheme.titleLarge),
                 Row(
                   children: [
                     IconButton(
                       icon: const Icon(Icons.arrow_back_ios, size: 16),
                       onPressed: _page > 0 ? () {
                         setState(() => _page--);
                         _loadHistory();
                       } : null,
                     ),
                     Text('Page ${_page + 1}'),
                     IconButton(
                       icon: const Icon(Icons.arrow_forward_ios, size: 16),
                       onPressed: _history.length == 50 ? () {
                         setState(() => _page++);
                         _loadHistory();
                       } : null,
                     ),
                   ],
                 )
              ],
            ),
            const SizedBox(height: 16),
            if (_history.isEmpty)
              const Text('No emails sent yet.')
            else
              Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('Recipient')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Subject')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Status')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Sent At')),
                    ],
                  ),
                  ..._history.map((item) {
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['recipient'] ?? '')),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['subject'] ?? '')),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['status'] ?? '')),
                        Padding(padding: const EdgeInsets.all(8), child: Text(item['created_at'] != null ? DateTime.parse(item['created_at']).toLocal().toString() : '')),
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
