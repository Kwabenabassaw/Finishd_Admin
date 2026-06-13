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
    final response = await _client.rpc('get_approved_creators');
    return List<Map<String, dynamic>>.from(response);
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

  Future<List<Map<String, dynamic>>> getAllVideos() async {
    return await _client
        .from('creator_videos')
        .select(
          '*, profiles!creator_videos_creator_id_fkey(username, avatar_url)',
        )
        .order('created_at', ascending: false);
  }

  Future<void> deleteVideo(String videoId) async {
    await _client
        .from('creator_videos')
        .update({
          'status': 'removed',
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', videoId);
  }

  Future<List<Map<String, dynamic>>> getFlaggedVideos() async {
    return await _client
        .from('creator_videos')
        .select('*, profiles:creator_videos_creator_id_fkey(username, avatar_url)')
        .gt('report_count', 0)            // FIX: was filtering pending again — should be reported
        .order('report_count', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getCommunities() async {
    final response = await _client.rpc('get_communities');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final response = await _client.functions.invoke('admin-view-reports');
      if (response.status >= 400) {
        final errorMsg = (response.data is Map)
            ? (response.data['error'] ?? 'Failed to fetch reports')
            : 'Failed to fetch reports (status ${response.status})';
        throw Exception(errorMsg);
      }
      final data = response.data;
      if (data is! Map) throw Exception('Unexpected response format from admin-view-reports');
      final List<dynamic> reports = data['reports'] ?? [];
      return List<Map<String, dynamic>>.from(reports);
    } on FunctionException catch (e) {
      throw Exception('Failed to load reports: ${e.reasonPhrase ?? e.details}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final mappedAction = status.toLowerCase().contains('dismiss') ? 'dismiss' : 'resolve';
    await _client.functions.invoke('admin-view-reports', body: {
      'reportId': reportId,
      'action': mappedAction,
      'notes': 'Status updated to $status',
    });
  }

  Future<void> resolveReport(
    String reportId,
    String action,
    String notes,
  ) async {
    final mappedAction = action.toLowerCase() == 'dismissed' ? 'dismiss' : 'resolve';
    final response = await _client.functions.invoke('admin-view-reports', body: {
      'reportId': reportId,
      'action': mappedAction,
      'notes': notes.isNotEmpty ? notes : null,
    });
    if (response.status >= 400) {
      final errorMsg = (response.data is Map)
          ? (response.data['error'] ?? 'Failed to resolve report')
          : 'Failed to resolve report (status ${response.status})';
      throw Exception(errorMsg);
    }
  }

  Future<void> warnUser(String userId, String reason) async =>
      _client.rpc('warn_user', params: {'p_user_id': userId, 'p_reason': reason});

  Future<void> suspendUser(String userId, String reason, int durationHours) async =>
      _client.rpc('suspend_user', params: {
        'p_user_id': userId,
        'p_reason': reason,
        'p_duration_hours': durationHours,
      });

  Future<void> deleteContent(String targetType, String targetId, String reason) async =>
      _client.rpc('admin_delete_content', params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_reason': reason,
      });

  Future<void> hideContent(String targetType, String targetId, bool hide) async =>
      _client.rpc('admin_hide_content', params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_hide': hide,
      });

  Future<void> flagReporter(String reporterId, String reason, int durationHours) async =>
      _client.rpc('flag_reporter', params: {
        'p_reporter_id': reporterId,
        'p_reason': reason,
        'p_duration_hours': durationHours,
      });

  Future<Map<String, dynamic>?> getContentContext(String targetType, String targetId) async {
    final result = await _client.rpc('admin_get_content_context', params: {
      'p_target_type': targetType,
      'p_target_id': targetId,
    });
    if (result == null) return null;
    return result as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getDeletionSubmissions() async {
    return await _client
        .from('deletion_submissions')
        .select('*')
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    return await _client
        .from('audit_log_view')
        .select('*')
        .limit(limit);
  }

  Future<void> broadcastAnnouncement({
    required String title,
    required String body,
    String type = 'announcement',
  }) async {
    await _client.functions.invoke('broadcast-announcement', body: {
      'title': title,
      'body': body,
      'type': type,
    });
  }

  Future<String> getSignedVideoUrl(String path) async {
    return await _client.storage
        .from('creator-videos')
        .createSignedUrl(path, 60 * 60);
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

    // FIX: target_id is UUID in the new schema — must be passed as a valid column value
    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,   // UUID string — Supabase client handles the cast
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

  Future<List<Map<String, dynamic>>> getDailyActiveUsers(int days) async {
    final response = await _client.rpc(
      'get_daily_active_users',
      params: {'p_days': days},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDailyVideoCompletion(int days) async {
    final response = await _client.rpc(
      'get_daily_video_completion',
      params: {'p_days': days},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDailyScrollDepth(int days) async {
    final response = await _client.rpc(
      'get_daily_scroll_depth',
      params: {'p_days': days},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDailyCommunityEngagement(int days) async {
    final response = await _client.rpc(
      'get_daily_community_engagement',
      params: {'p_days': days},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> unbanUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_banned': false, 'ban_reason': null})
        .eq('id', userId);

    // FIX: persist the unban action in moderation_actions
    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,   // UUID string — Supabase client handles the cast
      'action': 'unban',
    });
  }

  Future<void> updateUserStatus(String userId, String action, bool value) async {
    final Map<String, dynamic> updateData = {};
    if (action == 'suspend') {
      updateData['is_suspended'] = value;
      if (value) {
        updateData['suspension_end_timestamp'] = DateTime.now().add(const Duration(days: 7)).toIso8601String();
        updateData['suspension_reason'] = 'Admin action';
      } else {
        updateData['suspension_end_timestamp'] = null;
        updateData['suspension_reason'] = null;
      }
    } else if (action == 'shadowban') {
      updateData['is_shadowbanned'] = value;
    }

    await _client.from('profiles').update(updateData).eq('id', userId);

    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,
      'action': action,
      'reason': 'Admin action: ${value ? 'applied' : 'removed'}',
    });
  }

  Future<void> freezeCommunity(int communityId, String reason) async {
    await _client.rpc(
      'freeze_community',
      params: {'p_community_id': communityId, 'p_reason': reason},
    );
  }

  Future<void> deleteUser(String userId) async {
    await _client.functions.invoke('delete-account', body: {
      'target_user_id': userId,
    });

    // Optionally log this in moderation_actions
    await _client.from('moderation_actions').insert({
      'actor_id': _client.auth.currentUser?.id,
      'target_type': 'user',
      'target_id': userId,
      'action': 'delete',
      'reason': 'Admin deleted user account entirely',
    });
  }
}
