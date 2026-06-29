import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Templates ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTemplates() async {
    return await _client
        .from('email_templates')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> createTemplate(Map<String, dynamic> template) async {
    await _client.from('email_templates').insert(template);
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> template) async {
    template['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('email_templates').update(template).eq('id', id);
  }

  Future<void> deleteTemplate(String id) async {
    await _client.from('email_templates').delete().eq('id', id);
  }

  // ── Queue & Sending ──────────────────────────────────────────────────────

  Future<void> queueEmail({
    required String target,
    required String subject,
    required String htmlBody,
    String? templateId,
    Map<String, dynamic>? variables,
  }) async {
    await _client.functions.invoke('queue-email', body: {
      'target': target,
      'subject': subject,
      'htmlBody': htmlBody,
      'templateId': templateId,
      'variables': variables ?? {},
    });
  }

  Future<List<Map<String, dynamic>>> getQueue({int limit = 50}) async {
    return await _client
        .from('email_queue')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<void> retryQueueItem(String id) async {
    await _client.from('email_queue').update({
      'status': 'pending',
      'retry_count': 0,
      'error_message': null,
      'scheduled_for': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> cancelQueueItem(String id) async {
    await _client.from('email_queue').update({
      'status': 'cancelled',
    }).eq('id', id);
  }

  // ── History & Stats ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistory({int limit = 50, int page = 0}) async {
    return await _client
        .from('email_logs')
        .select('*, email_templates(name)')
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Quick aggregation
    final sentRes = await _client.from('email_logs').select('id').count(CountOption.exact);
    final queueRes = await _client.from('email_queue').select('id').eq('status', 'pending').count(CountOption.exact);
    final failedRes = await _client.from('email_queue').select('id').eq('status', 'failed').count(CountOption.exact);
    
    return {
      'total_sent': sentRes.count ?? 0,
      'queue_size': queueRes.count ?? 0,
      'failed': failedRes.count ?? 0,
    };
  }

  // ── Admin Alerts ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAdminAlerts() async {
    return await _client
        .from('admin_notifications')
        .select()
        .eq('is_read', false)
        .order('created_at', ascending: false);
  }

  Future<void> markAlertAsRead(String id) async {
    await _client.from('admin_notifications').update({
      'is_read': true
    }).eq('id', id);
  }

  RealtimeChannel subscribeToAlerts(void Function() onAlert) {
    final channel = _client.channel('public_admin_notifications');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'admin_notifications',
      callback: (payload) {
        onAlert();
      },
    ).subscribe();
    return channel;
  }
}
