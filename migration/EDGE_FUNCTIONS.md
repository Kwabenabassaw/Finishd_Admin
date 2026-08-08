# Edge Functions Analysis

## Overview
The platform utilizes Supabase Edge Functions (Deno) for asynchronous processing, integration with external services (Firebase Cloud Messaging), administrative actions, and data aggregation/algorithms.

## Functions Inventory

### 1. `admin-moderate-video`
- **Purpose**: Allows admins to review reported videos, updating their status (approve, reject, remove) and managing the associated creator trust scores.
- **Inputs**: `{ targetId, targetType, action, reason, metadata }`
- **Dependencies**: Depends heavily on the `creator_videos`, `reports`, and `moderation_actions` tables.
- **Risks & Scalability**: Synchronous updates to trust scores might slow down response times. Potential failure if cascading updates fail.
- **Migration Need**: Will be heavily used by the new React Admin Dashboard for moderation tools.

### 2. `admin-view-reports`
- **Purpose**: (Assuming standard report fetching based on typical folder naming). Exposes complex report views to the admin.
- **Dependencies**: Relies on auth.uid() and role checks.
- **Migration Need**: React will need to fetch from this function or replace it with direct Supabase PostgREST calls if RLS allows.

### 3. `broadcast-announcement`
- **Purpose**: Allows admins to push global announcements to all users via FCM (`all_users` topic) and inserts them into the `notifications` database table via the `send_global_notification` RPC.
- **Inputs**: `{ title, body, type, image_url, metadata }`
- **Dependencies**: Requires `FCM` setup (`_shared/fcm.ts`), Supabase Service Role for DB inserts.
- **Risks & Scalability**: Firebase topic messaging scales well, but the internal RPC (`send_global_notification`) must handle inserting potentially millions of rows efficiently.

### 4. `creator-application-review`
- **Purpose**: Approves or rejects creator applications, transitioning users to the 'creator' role.
- **Inputs**: `{ applicationId, action: 'approve' | 'reject', reviewNotes }`
- **Dependencies**: Updates `creator_applications` and `profiles` using the Service Role Key.
- **Risks**: Modifies core identity roles. Must ensure secure authentication contexts.

### 5. `aggregate-engagement`
- **Purpose**: Calculates an "engagement score" for a single video based on view count, watch time, completion percentage, and recency decay.
- **Inputs**: `{ videoId }`
- **Risks & Scalability**: Uses multiple `reduce` calls on potentially large arrays of events. (Memory note: `for-of` loop is ~12x faster, this is a known technical debt item to refactor for scale).

### 6. `compute-feed-rankings`
- **Purpose**: Scheduled cron job that processes engagement for the entire platform to compute `for_you` and `trending` feed rankings.
- **Logic**: Aggregates `video_engagement_events` from the last 7 days, deduplicates, calculates scores, updates `creator_videos`, rebuilds `feed_rankings`, and purges old events.
- **Risks & Scalability**: **High Risk**. Iterating over `uniqueVideoIds` sequentially and doing individual `select` and `update` queries inside a loop will severely bottleneck at scale. This needs to be rewritten into bulk SQL operations or moved to a specialized data pipeline (e.g. Postgres cron/pg_cron or a dedicated worker) rather than an Edge Function with timeout limits.

## Suggested Refactors Before Migration
- **`compute-feed-rankings`**: Convert loop-based SQL queries into bulk `INSERT ... ON CONFLICT` or pure SQL RPCs.
- **`aggregate-engagement`**: Optimize array aggregations per previous architectural notes (switch to single `for-of` loops).
