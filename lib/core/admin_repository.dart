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

  Future<void> updateUserStatus(String userId, String action, bool value) async {
    await _service.updateUserStatus(userId, action, value);
  }

  Future<void> deleteUser(String userId) async {
    await _service.deleteUser(userId);
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

  Future<List<Map<String, dynamic>>> getDeletionSubmissions() async {
    return _service.getDeletionSubmissions();
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    return _service.getAuditLogs();
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
    // FIX: communities.id is BIGINT — parse before passing to any query or RPC
    final communityIdInt = int.tryParse(communityId);
    if (communityIdInt == null) throw ArgumentError('Invalid communityId: $communityId');

    if (status == 'suspended') {
      await _service.freezeCommunity(communityIdInt, 'Admin action');
    } else {
      await _service.client
          .from('communities')
          .update({'status': status})
          .eq('id', communityIdInt);   // FIX: use int not String
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

  // ── Community Post Moderation ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommunityPosts(String communityId) async {
    // FIX: communities.id is BIGINT
    final response = await _service.client
        .from('community_posts')
        .select()
        .eq('community_id', int.parse(communityId))
        .order('created_at', ascending: false);
        
    if (response.isEmpty) return [];
    
    final authorIds = response.map((m) => m['author_id']).where((id) => id != null).toList();
    if (authorIds.isEmpty) return List<Map<String, dynamic>>.from(response);
    
    final profilesResponse = await _service.client
        .from('profiles')
        .select('id, username, avatar_url, display_name')
        .inFilter('id', authorIds);
        
    final profilesMap = {for (var p in profilesResponse) p['id']: p};
    
    return response.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['author'] = profilesMap[m['author_id']];
      return map;
    }).toList();
  }

  Future<void> lockCommunityPost(String postId, bool isLocked) async {
    await _service.client
        .from('community_posts')
        .update({'is_locked': isLocked})
        .eq('id', postId);
  }

  Future<void> pinCommunityPost(String postId, bool isPinned) async {
    await _service.client
        .from('community_posts')
        .update({
          'pinned_at': isPinned ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', postId);
  }

  Future<void> hideCommunityPost(String postId, bool isHidden) async {
    await _service.client
        .from('community_posts')
        .update({
          'deleted_at': isHidden ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', postId);
  }

  // ── Community Comments Moderation ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommunityComments(String postId) async {
    final response = await _service.client
        .from('community_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
        
    if (response.isEmpty) return [];
    
    final authorIds = response.map((m) => m['author_id']).where((id) => id != null).toList();
    if (authorIds.isEmpty) return List<Map<String, dynamic>>.from(response);
    
    final profilesResponse = await _service.client
        .from('profiles')
        .select('id, username, avatar_url, display_name')
        .inFilter('id', authorIds);
        
    final profilesMap = {for (var p in profilesResponse) p['id']: p};
    
    return response.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['author'] = profilesMap[m['author_id']];
      return map;
    }).toList();
  }

  Future<void> hideCommunityComment(String commentId, bool isHidden) async {
    await _service.client
        .from('community_comments')
        .update({
          'deleted_at': isHidden ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', commentId);
  }

  // ── Community Members Moderation ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCommunityMembers(String communityId) async {
    // FIX: communities.id is BIGINT
    final response = await _service.client
        .from('community_members')
        .select('community_id, user_id, role, joined_at')
        .eq('community_id', int.parse(communityId))
        .order('joined_at', ascending: true);
        
    final members = List<Map<String, dynamic>>.from(response);
    if (members.isEmpty) return [];
    
    final userIds = members.map((m) => m['user_id']).toList();
    final profilesResponse = await _service.client
        .from('profiles')
        .select('id, username, avatar_url, display_name')
        .inFilter('id', userIds);
        
    final profilesMap = {for (var p in profilesResponse) p['id']: p};
    
    return members.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['user'] = profilesMap[m['user_id']];
      return map;
    }).toList();
  }

  Future<void> updateCommunityMemberRole(String communityId, String userId, String newRole) async {
    // FIX: communities.id is BIGINT
    await _service.client
        .from('community_members')
        .update({'role': newRole})
        .eq('community_id', int.parse(communityId))
        .eq('user_id', userId);
  }

  Future<void> removeCommunityMember(String communityId, String userId) async {
    // FIX: communities.id is BIGINT
    await _service.client
        .from('community_members')
        .delete()
        .eq('community_id', int.parse(communityId))
        .eq('user_id', userId);
  }

  // ── Community Metadata Management ─────────────────────────────────────────

  Future<void> createCommunity(Map<String, dynamic> data) async {
    await _service.client
        .from('communities')
        .insert(data);
  }

  Future<void> updateCommunity(String communityId, Map<String, dynamic> data) async {
    // FIX: communities.id is BIGINT
    await _service.client
        .from('communities')
        .update(data)
        .eq('id', int.parse(communityId));
  }
}
