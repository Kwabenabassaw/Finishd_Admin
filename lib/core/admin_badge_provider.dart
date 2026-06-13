import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBadgeProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  
  int _pendingApplications = 0;
  int _pendingVideos = 0;
  int _pendingReports = 0;

  int get pendingApplications => _pendingApplications;
  int get pendingVideos => _pendingVideos;
  int get pendingReports => _pendingReports;

  int get totalBadges => _pendingApplications + _pendingVideos + _pendingReports;

  RealtimeChannel? _channel;

  AdminBadgeProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. Initial fetch
    await fetchCounts();

    // 2. Setup Realtime subscription
    try {
      _channel = _client.channel('admin_badges_channel');
      
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'creator_applications',
        callback: (payload) {
          debugPrint('Realtime change in creator_applications: ${payload.eventType}');
          _fetchApplicationsCount();
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'creator_videos',
        callback: (payload) {
          debugPrint('Realtime change in creator_videos: ${payload.eventType}');
          _fetchVideosCount();
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reports',
        callback: (payload) {
          debugPrint('Realtime change in reports: ${payload.eventType}');
          _fetchReportsCount();
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Error setting up Realtime subscription: $e');
    }
  }

  Future<void> fetchCounts() async {
    await Future.wait([
      _fetchApplicationsCount(),
      _fetchVideosCount(),
      _fetchReportsCount(),
    ]);
  }

  Future<void> _fetchApplicationsCount() async {
    try {
      final res = await _client
          .from('creator_applications')
          .select('id')
          .eq('status', 'pending');
      _pendingApplications = res.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching creator_applications count: $e');
    }
  }

  Future<void> _fetchVideosCount() async {
    try {
      final res = await _client
          .from('creator_videos')
          .select('id')
          .eq('status', 'pending');
      _pendingVideos = res.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching creator_videos count: $e');
    }
  }

  Future<void> _fetchReportsCount() async {
    try {
      final res = await _client
          .from('reports')
          .select('id')
          .eq('status', 'pending');
      _pendingReports = res.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching reports count: $e');
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }
}
