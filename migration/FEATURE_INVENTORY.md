# Admin Feature Inventory

## 1. Dashboard (`lib/features/dashboard`)
- **Purpose**: High-level overview of platform metrics.
- **Backend Dependencies**: RPC `get_admin_dashboard_stats()`.
- **Migration Complexity**: Low. Standard charts and stat cards.
- **Recommended React Architecture**: Recharts for visualizations, TanStack Query for caching the RPC call.

## 2. Analytics (`lib/features/analytics`)
- **Purpose**: Daily user and video stats.
- **Backend Dependencies**: RPCs `getDailyUserStats`, `getDailyVideoStats`.
- **Migration Complexity**: Low.
- **Recommended React Architecture**: Time-series charts using Recharts.

## 3. Users (`lib/features/users`)
- **Purpose**: Search, view, ban, unban, and delete users.
- **Backend Dependencies**: RPC `get_admin_users()`, `updateUserStatus`, `banUser`, `unbanUser`, `deleteUser`.
- **Migration Complexity**: Medium. Requires a robust data table with pagination and server-side searching.
- **Recommended React Architecture**: `@tanstack/react-table` with server-side pagination.

## 4. Creators & Applications (`lib/features/creators`, `lib/features/applications`)
- **Purpose**: Review creator applications and manage approved creators.
- **Backend Dependencies**: RPCs `getApprovedCreators()`, `getPendingCreatorApplications()`, `approve_creator_application()`, `reject_creator_application()`.
- **Migration Complexity**: Low.
- **Recommended React Architecture**: Standard data tables with modal confirmation for approve/reject actions.

## 5. Moderation (`lib/features/moderation`, `lib/features/reports`, `lib/features/user_reports`)
- **Purpose**: Review pending videos, resolve reports, manage deletion submissions.
- **Backend Dependencies**: RPCs `getPendingReviewVideos()`, `getReports()`, `resolveReport()`, `getDeletionSubmissions()`. Updates `creator_videos` directly for video moderation. Edge function `admin-moderate-video`.
- **Migration Complexity**: High. Moderation tools require high reliability, potential video playback for reviews, and complex state updates upon resolution.
- **Recommended React Architecture**: Dedicated moderation queue UI. Prefetching next items using TanStack Query. Video player component.

## 6. Communities (`lib/features/communities`)
- **Purpose**: Manage communities, community posts, comments, and members.
- **Backend Dependencies**: `getCommunities()`, `updateCommunityStatus()`, direct queries to `community_posts`, `community_comments`, `community_members`.
- **Migration Complexity**: Medium.
- **Recommended React Architecture**: Nested routing (e.g., `/communities/[id]/posts`) to manage deep navigation cleanly.

## 7. Announcements (`lib/features/announcements`)
- **Purpose**: Send global push notifications and in-app announcements.
- **Backend Dependencies**: Edge Function `broadcast-announcement` which calls RPC `send_global_notification` and Firebase Cloud Messaging.
- **Migration Complexity**: Low. Form submission.
- **Recommended React Architecture**: `react-hook-form` with Zod validation to ensure title/body are provided.

## 8. Feed Control & ML (`lib/features/feed`, `lib/features/ml`)
- **Purpose**: Manually trigger feed ranking computation and creator trust score recalculation.
- **Backend Dependencies**: RPCs `compute_feed_rankings()`, `computeCreatorTrustScores()`.
- **Migration Complexity**: Low.
- **Recommended React Architecture**: Simple control panel with loading states.

## 9. Settings (`lib/features/settings`)
- **Purpose**: Manage global application settings.
- **Backend Dependencies**: `getAdminSettings()`, `updateAdminSetting()`.
- **Migration Complexity**: Low.

## 10. Audit Logs (`lib/features/logs`)
- **Purpose**: Track admin actions.
- **Backend Dependencies**: View `audit_log_view`.
- **Migration Complexity**: Medium. Likely requires heavy pagination.
- **Recommended React Architecture**: `@tanstack/react-table` with infinite scrolling or robust pagination.
