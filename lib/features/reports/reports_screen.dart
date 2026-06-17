import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _fetchReports();
    }
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final status = _tabController.index == 0 ? 'pending' : 'resolved';
      final reports = await repository.getReports(status: status);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    }
  }


  Future<void> _banUser(String userId, String reason, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.banUser(userId, reason);
      await repo.resolveReport(reportId, 'resolved', 'User banned: $reason');
      await _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned and report resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error banning user: $e')));
      }
    }
  }

  Future<void> _warnUser(String userId, String reason, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.warnUser(userId, reason);
      await repo.resolveReport(reportId, 'resolved', 'User warned: $reason');
      await _fetchReports();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User warned')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _suspendUser(String userId, String reason, int durationHours, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.suspendUser(userId, reason, durationHours);
      await repo.resolveReport(reportId, 'resolved', 'User suspended for $durationHours hours: $reason');
      await _fetchReports();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User suspended')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteContent(String targetType, String targetId, String reason, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.deleteContent(targetType, targetId, reason);
      await repo.resolveReport(reportId, 'resolved', 'Content deleted');
      await _fetchReports();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _hideContent(String targetType, String targetId, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.hideContent(targetType, targetId, true);
      await repo.resolveReport(reportId, 'resolved', 'Content hidden');
      await _fetchReports();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content hidden')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unbanUser(String userId, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.unbanUser(userId);
      await _resolveWithNotes(reportId, 'resolved', 'User unbanned');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unbanned')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unsuspendUser(String userId, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.unsuspendUser(userId);
      await _resolveWithNotes(reportId, 'resolved', 'User unsuspended');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unsuspended')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unhideContent(String targetType, String targetId, String reportId) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.hideContent(targetType, targetId, false);
      await _resolveWithNotes(reportId, 'resolved', 'Content unhidden');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content unhidden')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _flagReporter(String reporterId, String reason) async {
    final repo = context.read<AdminRepository>();
    try {
      await repo.flagReporter(reporterId, reason, 24);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporter flagged for 24h')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _viewContext(BuildContext context, String targetType, String targetId) async {
    final repo = context.read<AdminRepository>();
    try {
      final contextData = await repo.getContentContext(targetType, targetId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Content Context'),
            content: SingleChildScrollView(
              child: Text(contextData.toString()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching context: $e')));
    }
  }

  void _promptWarnUser(String userId, String reportId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warn User'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _warnUser(userId, ctrl.text, reportId);
            },
            child: const Text('Warn'),
          ),
        ],
      ),
    );
  }

  void _promptDeleteContent(String targetType, String targetId, String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteContent(targetType, targetId, 'Admin deletion', reportId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _promptSuspendUser(String userId, String reportId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend User (24h)'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _suspendUser(userId, ctrl.text, 24, reportId);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Moderation Queue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Resolved'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reports.isEmpty
                    ? const Center(child: Text('No reports found.'))
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        columns: const [
                          DataColumn2(label: Text('Type'), size: ColumnSize.S),
                          DataColumn(label: Text('Reason')),
                          DataColumn(
                            label: Text('Reported User'),
                          ), // Adjusted from Severity to Reported User for better utility
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _reports.map((report) {
                          final reportedUser = report['reported_user'] ?? {};
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(report['target_type'] ?? 'General'),
                              ), // Use target_type
                              DataCell(Text(report['reason'] ?? 'No reason')),
                              DataCell(
                                Text(reportedUser['username'] ?? 'Unknown'),
                              ),
                              DataCell(
                                Text(
                                  report['created_at']?.split('T')[0] ?? '-',
                                ),
                              ),
                              DataCell(Text(report['status'] ?? 'Pending')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    _showReportDetails(context, report);
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> report) {
    final reportedUser = report['reported_user'] ?? {};
    final reportedUserId = report['reported_user_id'];
    final reportId = report['id']?.toString();
    final targetType = (report['target_type'] ?? 'unknown') as String;
    final targetId = (report['target_id']?.toString() ?? report['target_id_int']?.toString() ?? '-');
    final reason = (report['reason'] ?? '-') as String;
    final status = (report['status'] ?? 'pending') as String;
    final additionalInfo = report['additional_info'];
    final reporterId = report['reporter_id'];
    final communityId = report['community_id'];
    final chatId = report['chat_id'];
    final createdAt = report['created_at']?.toString().split('T')[0] ?? '-';
    final resolvedAt = report['resolved_at']?.toString().split('T')[0];
    final resolutionNotes = report['resolution_notes'];

    // Derive severity from reason for display
    final highSeverityReasons = ['harassment', 'hate', 'inappropriate'];
    final medSeverityReasons = ['spam', 'misinformation'];
    final String severity;
    final Color severityColor;
    if (highSeverityReasons.contains(reason)) {
      severity = 'High';
      severityColor = Colors.red;
    } else if (medSeverityReasons.contains(reason)) {
      severity = 'Medium';
      severityColor = Colors.orange;
    } else {
      severity = 'Low';
      severityColor = Colors.blue;
    }

    // Format target type for display
    final String displayType = targetType
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Report — $displayType'),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Content Info ──────────────────────────────────────────
                _SectionHeader('Reported Content'),
                _DetailRow(label: 'Content Type', value: displayType),
                _DetailRow(
                  label: 'Content ID',
                  value: targetId,
                  monospace: true,
                  truncate: true,
                ),
                if (communityId != null)
                  _DetailRow(label: 'Community ID', value: communityId.toString(), monospace: true, truncate: true),
                if (chatId != null)
                  _DetailRow(label: 'Chat ID', value: chatId.toString(), monospace: true, truncate: true),
                const SizedBox(height: 12),

                // ── People ────────────────────────────────────────────────
                _SectionHeader('People'),
                _DetailRow(
                  label: 'Reported User',
                  value: reportedUser['username'] ?? 'No profile (external content)',
                ),
                if (reportedUserId != null)
                  _DetailRow(label: 'Reported UID', value: reportedUserId.toString(), monospace: true, truncate: true),
                if (reporterId != null)
                  _DetailRow(label: 'Reporter UID', value: reporterId.toString(), monospace: true, truncate: true),
                const SizedBox(height: 12),

                // ── Report Info ───────────────────────────────────────────
                _SectionHeader('Report'),
                _DetailRow(label: 'Reason', value: reason),
                _DetailRow(label: 'Submitted', value: createdAt),
                _DetailRow(label: 'Status', value: status),
                if (resolvedAt != null)
                  _DetailRow(label: 'Resolved On', value: resolvedAt),
                const SizedBox(height: 12),

                // ── User's Description ────────────────────────────────────
                if (additionalInfo != null && additionalInfo.toString().isNotEmpty) ...[
                  _SectionHeader('User Description'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      additionalInfo.toString(),
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Previous Resolution Notes ─────────────────────────────
                if (resolutionNotes != null && resolutionNotes.toString().isNotEmpty) ...[
                  _SectionHeader('Previous Resolution Notes'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Text(resolutionNotes.toString()),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Admin Notes Input ─────────────────────────────────────
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Admin Notes (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add resolution notes...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Content Actions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (targetType != 'user') ...[
                      if (status == 'pending') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _promptDeleteContent(targetType, targetId, reportId!);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_off, size: 16),
                          label: const Text('Hide'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _hideContent(targetType, targetId, reportId!);
                          },
                        ),
                      ],
                      if (status == 'resolved' || status == 'dismissed') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Unhide'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _unhideContent(targetType, targetId, reportId!);
                          },
                        ),
                      ],
                      OutlinedButton.icon(
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Context'),
                        onPressed: () {
                          _viewContext(context, targetType, targetId);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'User Actions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (reportedUserId != null) ...[
                      if (status == 'pending') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.warning, size: 16),
                          label: const Text('Warn'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _promptWarnUser(reportedUserId.toString(), reportId!);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('Suspend (24h)'),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _promptSuspendUser(reportedUserId.toString(), reportId!);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.block, size: 16),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          label: const Text('Ban User'),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _banUser(reportedUserId.toString(), reason, reportId!);
                          },
                        ),
                      ],
                      if (status == 'resolved' || status == 'dismissed') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Unsuspend User'),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _unsuspendUser(reportedUserId.toString(), reportId!);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings_backup_restore, size: 16),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                          label: const Text('Unban User'),
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _unbanUser(reportedUserId.toString(), reportId!);
                          },
                        ),
                      ]
                    ],
                    if (reporterId != null && status == 'pending') ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.flag, size: 16),
                        label: const Text('Flag Reporter'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _flagReporter(reporterId.toString(), 'False report spam');
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (status == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resolveWithNotes(reportId!, 'dismissed', notesController.text);
              },
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resolveWithNotes(reportId!, 'resolved', notesController.text);
              },
              child: const Text('Mark Resolved'),
            ),
          ],
          if (status != 'pending') ...[
            FilledButton.tonal(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resolveWithNotes(reportId!, 'pending', 'Reopened report');
              },
              child: const Text('Reopen Report'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveWithNotes(String reportId, String status, String notes) async {
    try {
      await context.read<AdminRepository>().resolveReport(
        reportId,
        status,
        notes.isNotEmpty ? notes : 'Updated via Admin Panel',
      );
      await _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}


class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final bool truncate;

  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.truncate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: truncate ? 1 : null,
              overflow: truncate ? TextOverflow.ellipsis : null,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: monospace ? 'monospace' : null,
                fontSize: monospace ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
