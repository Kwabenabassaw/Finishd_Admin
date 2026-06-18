# Realtime Systems Analysis

## Current Architecture
- The Finishd application heavily uses Supabase Realtime for:
  - Chat & Messaging (`chats`, `messages` tables).
  - Live moderation dashboards (if implemented).
  - Typing indicators & Presence (Supabase Presence).
  - Notifications.

## React Migration Considerations
1. **Connection Management**: React handles lifecycles differently than Flutter. We must ensure WebSocket connections are not duplicated on hot-reloads or component re-renders.
2. **Subscription Leaks**: A `useEffect` without a proper cleanup function (`supabase.removeChannel(channel)`) will cause subscription leaks, resulting in duplicate events and performance degradation.
3. **State Sync**: When a realtime event fires (e.g., a new report comes in), the React application should ideally invalidate the relevant TanStack Query cache rather than manually merging the payload into local state, reducing edge-case bugs.
