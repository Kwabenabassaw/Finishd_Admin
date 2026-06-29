import 'package:finishd_admin/features/email_center/email_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailRepository {
  final EmailService _service;

  EmailRepository(this._service);

  Future<List<Map<String, dynamic>>> getTemplates() => _service.getTemplates();
  Future<void> createTemplate(Map<String, dynamic> template) => _service.createTemplate(template);
  Future<void> updateTemplate(String id, Map<String, dynamic> template) => _service.updateTemplate(id, template);
  Future<void> deleteTemplate(String id) => _service.deleteTemplate(id);

  Future<void> sendEmail({
    required String target,
    required String subject,
    required String htmlBody,
    String? templateId,
    Map<String, dynamic>? variables,
  }) => _service.queueEmail(
    target: target,
    subject: subject,
    htmlBody: htmlBody,
    templateId: templateId,
    variables: variables,
  );

  Future<List<Map<String, dynamic>>> getQueue() => _service.getQueue();
  Future<void> retryQueueItem(String id) => _service.retryQueueItem(id);
  Future<void> cancelQueueItem(String id) => _service.cancelQueueItem(id);

  Future<List<Map<String, dynamic>>> getHistory({int page = 0}) => _service.getHistory(page: page);
  Future<Map<String, dynamic>> getDashboardStats() => _service.getDashboardStats();

  Future<List<Map<String, dynamic>>> getAdminAlerts() => _service.getAdminAlerts();
  Future<void> markAlertAsRead(String id) => _service.markAlertAsRead(id);
  
  RealtimeChannel subscribeToAlerts(void Function() onAlert) => _service.subscribeToAlerts(onAlert);
}
