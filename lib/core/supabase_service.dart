import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Accessors ─────────────────────────────────────────────────────────────

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;

  // ── RPC Wrappers ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return await _client.rpc('get_admin_dashboard_stats');
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final response = await _client.rpc(
      'get_admin_users',
      params: {'p_page': page, 'p_limit': limit, 'p_search': search},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> approveCreatorApplication(String applicationId) async {
    await _client.rpc(
      'approve_creator_application',
      params: {'p_app_id': applicationId},
    );
  }

  Future<void> rejectCreatorApplication(
    String applicationId,
    String reason,
  ) async {
    await _client.rpc(
      'reject_creator_application',
      params: {'p_app_id': applicationId, 'p_reason': reason},
    );
  }

  Future<void> computeFeedRankings() async {
    await _client.rpc('compute_feed_rankings');
  }

  Future<void> computeCreatorTrustScores() async {
    await _client.rpc('compute_creator_trust_scores');
  }

  // ── Typed Table Queries ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingCreatorApplications() async {
    return await _client
        .from('creator_applications')
        .select('*, profiles:user_id(username, avatar_url, role)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getApprovedCreators() async {
    // We can query profiles directly since we have an index on role/status
    return await _client
        .from('profiles')
        .select('*')
        .eq('role', 'creator')
        .eq('creator_status', 'approved')
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getPendingReviewVideos() async {
    return await _client
        .from('creator_videos')
        .select(
          '*, profiles!creator_videos_creator_id_fkey(username, avatar_url)',
        )
        .eq('status', 'pending')
        .order('created_at', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getFlaggedVideos() async {
    return await _client
        .from('creator_videos')
        .select('*, profiles:creator_id(username)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getCommunities() async {
    // Fetch all communities. Pagination might be needed later.
    return await _client
        .from('communities')
        .select('*')
        .order('member_count', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    return await _client
        .from('reports')
        .select('*, reported_user:reported_user_id(username)')
        .order('created_at', ascending: false);
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await _client.from('admin_settings').select();
    final Map<String, dynamic> settings = {};
    for (var item in response) {
      settings[item['key'] as String] = item['value'];
    }
    return settings;
  }

  Future<void> updateAdminSetting(String key, dynamic value) async {
    await _client.from('admin_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
    });
  }

  Future<void> banUser(String userId, String reason) async {
    await _client
        .from('profiles')
        .update({'is_banned': true, 'ban_reason': reason})
        .eq('id', userId);

    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,
      'action': 'ban',
      'reason': reason,
    });
  }

  // Placeholder for chart data - requires aggregation RPC
  // Future<List<Map<String, dynamic>>> getDailyStats(int days) async { ... }

  Future<List<Map<String, dynamic>>> getDailyUserStats(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return await _client
        .from('user_daily_stats')
        .select()
        .gte('date', startDate.toIso8601String())
        .order('date', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getDailyVideoStats(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return await _client
        .from('video_daily_stats')
        .select()
        .gte('date', startDate.toIso8601String())
        .order('date', ascending: true);
  }

  Future<void> unbanUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_banned': false, 'ban_reason': null})
        .eq('id', userId);

    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,
      'action': 'unban',
    });
  }

  Future<void> freezeCommunity(String communityId, String reason) async {
    await _client.rpc(
      'freeze_community',
      params: {'p_community_id': int.parse(communityId), 'p_reason': reason},
    );
  }

  Future<void> resolveReport(
    String reportId,
    String action,
    String notes,
  ) async {
    await _client.rpc(
      'resolve_report',
      params: {'p_report_id': reportId, 'p_action': action, 'p_notes': notes},
    );
  }
}
