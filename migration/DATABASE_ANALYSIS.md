# Database & Supabase Analysis

## Overview
The Finishd application relies heavily on Supabase Postgres. The database encompasses a large-scale social platform with content streaming, communities, chat, moderation, ML algorithms, and analytics.

## Tables & Architecture
- **Lookups**: `media_types`, `user_title_statuses`, `reaction_types`, `report_types`, `report_statuses`, `application_statuses`, `feed_categories`, `message_types`, `user_roles`, `community_roles`.
- **Profiles & Identity**: `profiles`, `user_devices` (for FCM tokens), `follows`, `blocked_users`.
- **Content Graph**: `creator_videos`, `video_hashtags`, `hashtags`, `video_interactions` (likes, watch time), `video_counter_events`.
- **Social & Communities**: `communities`, `community_members`, `community_posts`, `community_comments`.
- **Chat & Messaging**: `chats`, `chat_members`, `messages`.
- **Trust & Moderation**: `reports`, `moderation_actions`, `creator_trust_scores`, `user_trust_scores`, `blocked_terms`, `deletion_submissions`.
- **Algorithms & ML**: `ml_feature_store`, `user_affinity_vectors`, `video_score_snapshots`.
- **Analytics**: `creator_daily_stats`, `video_retention_buckets`, `feed_sessions`, `feed_impressions`.
- **Admin**: `admin_settings`.

## Views
- `audit_log_view`: Joins `moderation_actions` with `profiles` to render a human-readable audit trail of admin actions.

## Security (RLS)
Row Level Security (RLS) is extensively used across tables:
- **Public access**: Lookups, hashtags, public profiles.
- **Role-based admin access**: `admin_settings`, `blocked_terms`, `reports`, `deletion_submissions` restricted to profiles with `role = 'admin'` or `'reviewer'`.
- **Owner access**: `user_trust_scores`, `feed_sessions`.

## Scalability & Performance Observations
- **Partitioning**: Uses table partitioning for high-volume event tables (`video_engagement_events`, `feed_impressions`) using a monthly cadence. This is highly scalable but requires automated cron jobs to create partitions.
- **Unlogged-style Events**: Uses simple tables like `video_counter_events` for high-velocity inserts to defer complex constraint checks, aggregated later.
- **Missing index risks**: We must map indexes on `reports`, `moderation_actions`, and `creator_videos` depending on admin filtering features (e.g. searching audit logs by date or admin username).
