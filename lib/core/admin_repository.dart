import 'package:finishd_admin/core/supabase_service.dart';

class AdminRepository {
  final SupabaseService _service;

  AdminRepository(this._service);

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    return _service.getAdminDashboardStats();
  }

  Future<List<Map<String, dynamic>>> getDailyUserStats(int days) async {
    return _service.getDailyUserStats(days);
  }

  Future<List<Map<String, dynamic>>> getDailyVideoStats(int days) async {
    return _service.getDailyVideoStats(days);
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsers({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    return _service.getAdminUsers(page: page, limit: limit, search: search);
  }

  Future<void> banUser(String userId, String reason) async {
    await _service.banUser(userId, reason);
  }

  Future<void> unbanUser(String userId) async {
    await _service.unbanUser(userId);
  }

  // ── Creators ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getApprovedCreators() async {
    return _service.getApprovedCreators();
  }

  Future<List<Map<String, dynamic>>> getPendingApplications() async {
    return _service.getPendingCreatorApplications();
  }

  Future<void> approveCreator(String applicationId) async {
    await _service.approveCreatorApplication(applicationId);
  }

  Future<void> rejectCreator(String applicationId, String reason) async {
    await _service.rejectCreatorApplication(applicationId, reason);
  }

  // ── Moderation ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingVideos() async {
    return _service.getPendingReviewVideos();
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    return _service.getReports();
  }

  Future<void> resolveReport(
    String reportId,
    String action,
    String notes,
  ) async {
    await _service.resolveReport(reportId, action, notes);
  }

  Future<void> approveVideo(String videoId) async {
    await _service.client
        .from('creator_videos')
        .update({
          'status': 'approved',
          'reviewed_by': _service.currentUser?.id,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', videoId);
  }

  Future<void> rejectVideo(String videoId, String reason) async {
    await _service.client
        .from('creator_videos')
        .update({
          'status': 'rejected',
          'reviewed_by': _service.currentUser?.id,
          'reviewed_at': DateTime.now().toIso8601String(),
          'rejection_reason': reason,
        })
        .eq('id', videoId);
  }

  // ── Communities ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommunities() async {
    return _service.getCommunities();
  }

  Future<void> updateCommunityStatus(String communityId, String status) async {
    if (status == 'suspended') {
      await _service.freezeCommunity(communityId, 'Admin action');
    } else {
      await _service.client
          .from('communities')
          .update({'status': status})
          .eq('id', communityId);
    }
  }

  // ── Settings & System ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    return _service.getAdminSettings();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _service.updateAdminSetting(key, value);
  }

  Future<void> deployFeedChanges() async {
    await _service.computeFeedRankings();
  }

  Future<void> computeCreatorTrustScores() async {
    await _service.computeCreatorTrustScores();
  }
}
