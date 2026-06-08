# Finishd Database Schema Documentation

This document provides a comprehensive, production-grade reference of the **Finishd Supabase database architecture**. It acts as the single source of truth for AI agents and developers building integrations, administrative panels, and performing data migrations.

---

## 1. Lookups & Constants Tables

These tables serve as reference enums to maintain strict data integrity.

### `media_types`
- **Purpose**: Defines allowed media categories.
- **Primary Key**: `value` (TEXT)
- **Values**: `'movie'`, `'tv'`

### `user_roles`
- **Purpose**: Standard platform user roles.
- **Primary Key**: `value` (TEXT)
- **Values**: `'user'`, `'creator'`, `'reviewer'`, `'admin'`

### `community_roles`
- **Purpose**: Access roles inside local communities.
- **Primary Key**: `value` (TEXT)
- **Values**: `'member'`, `'moderator'`, `'admin'`

### `reaction_types`
- **Purpose**: Emoji reactions allowed for creator videos.
- **Primary Key**: `value` (TEXT)
- **Values**: `'heart'`, `'laugh'`, `'wow'`, `'sad'`, `'angry'`

### `report_types`
- **Purpose**: Categorization of reported items.
- **Primary Key**: `value` (TEXT)
- **Values**: `'video'`, `'comment'`, `'user'`, `'community_post'`

### `report_statuses`
- **Purpose**: Status queue flags for reported items.
- **Primary Key**: `value` (TEXT)
- **Values**: `'pending'`, `'resolved'`, `'dismissed'`

### `application_statuses`
- **Purpose**: States for creator applications or appeals.
- **Primary Key**: `value` (TEXT)
- **Values**: `'pending'`, `'approved'`, `'rejected'`

---

## 2. Identity, Profiles & Applications

These tables handle user identities, verification processes, and push notification registrations.

### `profiles`
- **Purpose**: Extends Supabase's core `auth.users` identity. Synchronized automatically via `handle_new_user()` trigger.
- **Columns**:
  - `id`: UUID (Primary Key, FK → `auth.users` on delete CASCADE)
  - `username`: TEXT (Unique, nullable)
  - `first_name`: TEXT (Nullable)
  - `last_name`: TEXT (Nullable)
  - `avatar_url`: TEXT (Nullable)
  - `bio`: TEXT (Nullable)
  - `role`: TEXT (Default `'user'`, FK → `user_roles`)
  - `creator_status`: TEXT (Nullable, FK → `application_statuses`)
  - `creator_verified_at`: TIMESTAMPTZ (Nullable)
  - `is_banned`: BOOLEAN (Default `false`)
  - `is_suspended`: BOOLEAN (Default `false`)
  - `suspension_end_timestamp`: TIMESTAMPTZ (Nullable)
  - `suspension_reason`: TEXT (Nullable)
  - `ban_reason`: TEXT (Nullable)
  - `reputation_score`: NUMERIC (Default `0`)
  - `is_shadowbanned`: BOOLEAN (Default `false`)
  - `preferences`: JSONB (Default `'{}'::jsonb`)
  - `onboarding_completed`: BOOLEAN (Default `false`)
  - `firebase_uid`: TEXT (Unique, Nullable)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `updated_at`: TIMESTAMPTZ (Default `now()`)
- **Indexes**:
  - `idx_profiles_role` ON `profiles(role)`
  - `idx_profiles_creator_status` ON `profiles(creator_status) WHERE creator_status IS NOT NULL`
- **Row-Level Security (RLS)**:
  - Select: Allowed for anyone (`true`).
  - Update: Allowed if `auth.uid() = id` (User updating own profile) or if caller has `role = 'admin'`.

### `creator_applications`
- **Purpose**: Holds application forms filled by users wishing to obtain creator posting credentials.
- **Columns**:
  - `id`: UUID (Primary Key, Default `gen_random_uuid()`)
  - `user_id`: UUID (NOT NULL, FK → `profiles.id` on delete CASCADE)
  - `display_name`: TEXT (NOT NULL)
  - `bio`: TEXT (NOT NULL)
  - `content_intent`: TEXT[] (Array of tags describing plans)
  - `external_links`: JSONB (Socials or portfolios)
  - `status`: TEXT (Default `'pending'`, FK → `application_statuses`)
  - `reviewed_by`: UUID (Nullable, FK → `profiles.id`)
  - `review_notes`: TEXT (Nullable)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `reviewed_at`: TIMESTAMPTZ (Nullable)
- **Constraints**:
  - `unique_pending_application` UNIQUE(`user_id`, `status`): Restricts users to one active pending application at a time.
- **Indexes**:
  - `idx_creator_apps_user` ON `creator_applications(user_id)`
  - `idx_creator_apps_status` ON `creator_applications(status)`
- **RLS**:
  - Select/Insert: Allowed if `auth.uid() = user_id`.
  - Admin Select/Update: Allowed if caller has system `role IN ('admin', 'reviewer')`.

### `appeals`
- **Purpose**: Allows banned or suspended users to appeal administrative decisions.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `user_id`: UUID (FK → `profiles.id` on delete CASCADE)
  - `action_type`: TEXT (NOT NULL)
  - `original_reason`: TEXT (Nullable)
  - `appeal_message`: TEXT (NOT NULL)
  - `status`: TEXT (Default `'pending'`, FK → `application_statuses`)
  - `admin_notes`: TEXT (Nullable)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `updated_at`: TIMESTAMPTZ (Default `now()`)
- **RLS**:
  - Select/Insert: Allowed if `auth.uid() = user_id`.

### `user_devices`
- **Purpose**: Stores active Firebase Cloud Messaging (FCM) tokens for targeted push notifications.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `user_id`: UUID (NOT NULL, FK → `profiles.id` on delete CASCADE)
  - `fcm_token`: TEXT (NOT NULL)
  - `platform`: TEXT (CHECK: `platform IN ('ios', 'android', 'web')`)
  - `last_seen_at`: TIMESTAMPTZ (Default `now()`)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
- **Constraints**:
  - UNIQUE(`user_id`, `fcm_token`): Protects against duplicate tokens.
- **Indexes**:
  - `idx_ud_token` ON `user_devices(fcm_token)` (UNIQUE)
- **RLS**:
  - All operations: Allowed if `auth.uid() = user_id`.
  - Admin Select: Allowed for system `role IN ('admin', 'reviewer')`.

---

## 3. Communities System

Handles show-based user groups, posts, nested discussions, and votes.

### `communities`
- **Purpose**: Host discussion groups dedicated to a specific movie or show ID (TMDB reference).
- **Columns**:
  - `id`: BIGINT (Generated by Default as Identity, Primary Key)
  - `show_id`: INT (UNIQUE, NOT NULL - references TMDB ID)
  - `title`: TEXT (NOT NULL)
  - `poster_path`: TEXT (Nullable)
  - `media_type`: TEXT (FK → `media_types`)
  - `member_count`: INT (Default `0`)
  - `post_count`: INT (Default `0`)
  - `status`: TEXT (Default `'active'`, CHECK: `status IN ('active', 'flagged', 'suspended')`)
  - `toxicity_score`: NUMERIC(5,2) (Default `0`)
  - `last_activity_at`: TIMESTAMPTZ (Default `now()`)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `created_by`: UUID (FK → `auth.users`)
- **RLS**:
  - Select: Public read.
  - Insert: Allowed if caller is authenticated.
  - Update: Enabled for standard counter increments.

### `community_members`
- **Purpose**: Resolves community memberships and roles.
- **Columns**:
  - `community_id`: BIGINT (FK → `communities.id` on delete CASCADE)
  - `user_id`: UUID (FK → `auth.users.id` on delete CASCADE)
  - `role`: TEXT (Default `'member'`, FK → `community_roles`)
  - `joined_at`: TIMESTAMPTZ (Default `now()`)
- **Composite Primary Key**: `(community_id, user_id)`
- **RLS**:
  - Select: Public read.
  - Insert: Allowed if authenticated (matches joining a community).
  - Delete: Allowed if `auth.uid() = user_id` (matches leaving).

### `community_posts`
- **Purpose**: Posts created within a specific community.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `community_id`: BIGINT (FK → `communities.id` on delete CASCADE)
  - `show_id`: INT (TMDB Cache ID)
  - `author_id`: UUID (FK → `auth.users`)
  - `content`: TEXT
  - `media_urls`: TEXT[] (Attached photos/videos)
  - `media_types`: TEXT[]
  - `hashtags`: TEXT[]
  - `is_spoiler`: BOOLEAN (Default `false`)
  - `is_hidden`: BOOLEAN (Default `false`)
  - `is_locked`: BOOLEAN (Default `false`)
  - `pinned_at`: TIMESTAMPTZ (Nullable)
  - `score`: INT (Default `0`)
  - `upvotes`: INT (Default `0`)
  - `downvotes`: INT (Default `0`)
  - `comment_count`: INT (Default `0`)
  - `view_count`: INT (Default `0`)
  - `deleted_at`: TIMESTAMPTZ (Nullable - used for soft deletion)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `updated_at`: TIMESTAMPTZ (Default `now()`)
  - `last_activity_at`: TIMESTAMPTZ (Default `now()`)
- **Indexes**:
  - `idx_posts_community_created` ON `community_posts(community_id, created_at DESC)`
  - `idx_posts_author` ON `community_posts(author_id)`
  - `idx_posts_score` ON `community_posts(score DESC)`
- **RLS**:
  - Select: Allowed if `deleted_at IS NULL`.
  - Insert: Allowed if `auth.uid() = author_id`.
  - Update: Allowed if `auth.uid() = author_id` (editing) OR if moderator/admin is adjusting tags/states.

### `community_comments`
- **Purpose**: Discussion replies under a community post. Supports hierarchical comment threading.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `post_id`: UUID (NOT NULL, FK → `community_posts.id` on delete CASCADE)
  - `author_id`: UUID (FK → `auth.users`)
  - `content`: TEXT
  - `parent_id`: UUID (Nullable, FK → `community_comments.id` - self referential)
  - `upvotes`: INT (Default `0`)
  - `downvotes`: INT (Default `0`)
  - `is_hidden`: BOOLEAN (Default `false`)
  - `deleted_at`: TIMESTAMPTZ (Nullable - soft delete)
  - `created_at`: TIMESTAMPTZ (Default `now()`)
  - `updated_at`: TIMESTAMPTZ (Default `now()`)
- **Indexes**:
  - `idx_comments_post_created` ON `community_comments(post_id, created_at DESC)`
  - `idx_comments_parent` ON `community_comments(parent_id) WHERE parent_id IS NOT NULL`
  - `idx_comments_author` ON `community_comments(author_id)`
- **RLS**:
  - Select: Allowed if `deleted_at IS NULL`.
  - Insert/Update: Allowed if `auth.uid() = author_id`.

### `post_votes` & `comment_votes`
- **Purpose**: Ensures user restriction of 1 vote (upvote +1 or downvote -1) per post/comment.
- **Composite Primary Keys**: `(user_id, post_id)` and `(user_id, comment_id)`
- **Triggers**: Managed directly via `vote_on_post` functions updating aggregate scores instantly.

---

## 4. Short-Form Video Engine (Creator Videos)

Powerhouse of the TikTok-style vertical review system.

### `creator_videos`
- **Purpose**: Tracks uploads by approved video creators, tagged to dynamic show listings.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `creator_id`: UUID (NOT NULL, FK → `profiles.id`)
  - `video_url`: TEXT (Relative storage path in `creator-videos` bucket)
  - `thumbnail_url`: TEXT (Public asset URL in `creator-thumbnails` bucket)
  - `title`: TEXT (Review Title / TMDB Reference)
  - `description`: TEXT (Caption text containing extracted hashtags)
  - `tags`: TEXT[] (Extracted hashtags array)
  - `tmdb_id`: INT (TMDB Media Reference ID)
  - `tmdb_type`: TEXT (Movie/TV selection)
  - `spoiler`: BOOLEAN (Default `false`)
  - `duration_seconds`: INT (Max 60 seconds)
  - `status`: TEXT (Default `'pending'` - reviewed before publishing)
  - `reviewed_by`: UUID (FK → `profiles.id`)
  - `rejection_reason`: TEXT
  - `like_count`: INT (Default `0`, synced by reactions trigger)
  - `comment_count`: INT (Default `0`, synced by comments trigger)
  - `view_count`: INT (Default `0`)
  - `engagement_score`: NUMERIC(10,4) (Default `0` - for feed ranking algorithms)
  - `quality_score`: NUMERIC(10,4)
  - `deleted_at`: TIMESTAMPTZ (Soft delete flag)
  - `created_at` / `updated_at`: TIMESTAMPTZ (Managed automated timestamps)
- **Indexes**:
  - `idx_cv_creator` ON `creator_videos(creator_id)`
  - `idx_cv_status` ON `creator_videos(status)`
  - `idx_cv_feed` ON `creator_videos(status, created_at DESC) WHERE deleted_at IS NULL`
  - `idx_cv_engagement` ON `creator_videos(engagement_score DESC) WHERE status = 'approved'`
- **RLS**:
  - Select: Public select if `status = 'approved'` and `deleted_at IS NULL`. Own uploads readable at any time.
  - Insert: Only allowed if user's profile has `creator_status = 'approved'`.
  - Admin: System admins have full bypass.

### `video_reactions`
- **Purpose**: Maps user reactions to specific short videos. Unique constraint prevents duplicates.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `video_id`: UUID (FK → `creator_videos.id` on delete CASCADE)
  - `user_id`: UUID (FK → `profiles.id` on delete CASCADE)
  - `reaction_type`: TEXT (FK → `reaction_types`)
  - `emoji`: TEXT
  - `created_at`: TIMESTAMPTZ
- **Constraints**:
  - UNIQUE(`video_id`, `user_id`): One reaction per user per video.
- **Trigger**: On Insert/Delete, increments/decrements `creator_videos.like_count`.

---

## 5. Trust, Reports & Moderation

Core trust and safety infrastructure.

### `reports`
- **Purpose**: Universal reporting framework for system abuse tracking.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `reporter_id`: UUID (FK → `profiles.id` on delete SET NULL)
  - `target_id`: UUID (NOT NULL - polymorphic reference ID of post/comment/user)
  - `target_type`: TEXT (FK → `report_types` constant)
  - `reason`: TEXT (NOT NULL)
  - `additional_info`: TEXT
  - `content_snapshot`: JSONB (Captures state of reported item to prevent user editing escaping review)
  - `reported_user_id`: UUID (FK → `profiles.id` on delete CASCADE)
  - `severity`: TEXT (Default `'low'`)
  - `report_weight`: NUMERIC (Default `1.0`)
  - `status`: TEXT (Default `'pending'`, FK → `report_statuses`)
  - `reviewed_by`: UUID (FK → `profiles.id`)
  - `review_notes`: TEXT
  - `created_at` / `updated_at`: TIMESTAMPTZ
- **RLS**:
  - Insert: Allowed if `auth.uid() = reporter_id`.
  - Select: Users see own reports. Reviewers and Admins see all reports.

### `moderation_actions`
- **Purpose**: Master audit trail logs of all moderator actions.
- **Columns**:
  - `id`: UUID (Primary Key)
  - `actor_id`: UUID (NOT NULL, FK → `profiles.id`)
  - `target_type`: TEXT (CHECK: `target_type IN ('video', 'comment', 'user', 'community_post', 'community')`)
  - `target_id`: UUID (Nullable target reference ID)
  - `target_id_int`: BIGINT (Nullable target reference for community integer keys)
  - `action`: TEXT (CHECK: `action IN ('approve', 'reject', 'remove', 'suppress', 'unsuppress', 'ban', 'unban', 'suspend', 'unsuspend', 'warn', 'escalate')`)
  - `reason`: TEXT
  - `metadata`: JSONB (Default `'{}'`)
  - `created_at`: TIMESTAMPTZ
- **RLS**:
  - Full Access: Only users with `profiles.role IN ('admin', 'reviewer')`.

### `user_trust_scores` & `creator_trust_scores`
- **Purpose**: Algorithmic trust metrics to drive auto-moderation.
- **`user_trust_scores` Columns**:
  - `user_id`: UUID (Primary Key, FK → `profiles.id`)
  - `trust_score`: NUMERIC (Default `1.0`)
  - `reports_received`: INT
  - `false_reports_made`: INT
  - `actions_taken`: INT
- **`creator_trust_scores` Columns**:
  - `creator_id`: UUID (Primary Key, FK → `profiles.id`)
  - `trust_score`: NUMERIC(5,4) (Default `0.50`)
  - `approval_rate`: NUMERIC (approved / total uploads)
  - `total_uploads` / `total_approved` / `total_rejected` / `total_removed`: INT
  - `abuse_reports_received`: INT
  - `avg_completion_rate`: NUMERIC
  - `auto_approve_eligible`: BOOLEAN (Computed if trust > 0.85 & >10 uploads)

### `blocked_terms`
- **Purpose**: Word filter lists for automated comment and post pre-moderation.
- **Columns**:
  - `term`: TEXT (Primary Key)
  - `category`: TEXT (CHECK: `category IN ('hate', 'spam', 'adult', 'violence')`)
  - `severity`: TEXT (Default `'high'`)
  - `created_at`: TIMESTAMPTZ

---

## 6. Admin Panel Settings & System Control

### `admin_settings`
- **Purpose**: Dynamic settings and feature toggles for the core applications.
- **Columns**:
  - `key`: TEXT (Primary Key)
  - `value`: JSONB (NOT NULL)
  - `updated_at`: TIMESTAMPTZ (Default `now()`)
  - `updated_by`: UUID (FK → `profiles.id`)
- **Seeded Configuration Keys**:
  - `'maintenance_mode'`: `false`
  - `'enable_v2_feed'`: `true`
  - `'max_upload_size_mb'`: `100`
  - `'auto_moderation_enabled'`: `true`
  - `'feed_algorithm'`: `{"trending_weight": 0.4, "personalized_weight": 0.4, "friend_weight": 0.2, "ad_frequency": 0.1}`
- **RLS**:
  - Only accounts with `profiles.role = 'admin'` have permissions.

---

## 7. Storage Buckets

Defined inside Supabase storage rules.

### `creator-videos` (Private Bucket)
- **Use Case**: Houses compressed `.mp4` video files.
- **Path convention**: `creator-videos/{user_id}/{timestamp}.mp4`
- **Read Access**: Requires a signed URL generated via storage API (60-minute lifetime).
- **Upload Access**: Authorized only for users with `creator_status = 'approved'` uploading into their own `{user_id}` directory.

### `creator-thumbnails` (Public Bucket)
- **Use Case**: Public video thumbnail frame cover pictures.
- **Read Access**: Public read access via static URLs.

### `community-media` (Public Bucket)
- **Use Case**: Holds attachments uploaded to community discussion threads.
- **Path Convention**: `community-media/{community_id}/{user_id}/{filename}`
- **Write Access**: Validated via RLS checking if the user is a registered member of the `{community_id}`.

---

## 8. Database RPC Functions (Admins Only)

These Postgres functions run with `SECURITY DEFINER` privileges to bypass RLS safely after checking caller authorization.

### `get_admin_dashboard_stats()`
- **Returns**: `JSONB`
- **JSON Structure**:
  ```json
  {
    "daily_active_users": 1500,
    "new_users_today": 45,
    "videos_uploaded_today": 12,
    "pending_reports": 5
  }
  ```

### `approve_creator_application(p_app_id UUID)`
- **Task**: 
  1. Set application status to `'approved'`.
  2. Upgrade applicant's `profiles.role` to `'creator'` and `creator_status` to `'approved'`.
  3. Log event to `moderation_actions`.

### `reject_creator_application(p_app_id UUID, p_reason TEXT)`
- **Task**:
  1. Set application status to `'rejected'`.
  2. Populate review notes with `p_reason`.
  3. Log rejection into `moderation_actions`.

### `freeze_community(p_community_id BIGINT, p_reason TEXT)`
- **Task**:
  1. Update community status to `'suspended'`.
  2. Log suspension record into `moderation_actions` under target integer ID.

### `resolve_report(p_report_id UUID, p_action TEXT, p_notes TEXT)`
- **Task**: Resolves flag queues by updating report state to `'resolved'` or `'dismissed'`.

### `get_admin_users(p_page INT, p_limit INT, p_search TEXT)`
- **Returns**: A table of users including their private emails joined securely from `auth.users` to `public.profiles`, along with active reports counts. Strictly restricted to admin/reviewer roles.
