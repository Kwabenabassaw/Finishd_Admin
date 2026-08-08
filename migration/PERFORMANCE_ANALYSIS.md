# Performance & Scalability Analysis

## Current Bottlenecks
1. **Frontend Data Joining**: `AdminRepository` manually joins profiles to posts and comments. This should be handled by a PostgreSQL View or a joined query using Supabase's `select('*, profiles(*)')` syntax.
2. **Compute Feed Rankings**: The Edge Function iterates sequentially over videos. This will time out at scale.
3. **Array Aggregations**: Edge Functions using `reduce` multiple times on the same array are slow.

## Scalability Recommendations (Targeting 100K - 1M DAU)
- **Database Indexing**: Ensure indexes exist on all foreign keys (e.g., `user_id`, `video_id`) and heavily filtered columns (e.g., `status`, `created_at`).
- **Pagination**: The React Admin must strictly use server-side pagination for all tables. Do not fetch entire tables into memory.
- **Edge Caching**: Use Next.js Route Handlers to cache non-realtime statistics (like the dashboard overview) for a few minutes to reduce DB load.
- **Background Jobs**: Move heavy operations like `compute-feed-rankings` to a dedicated worker environment (like Inngest, Trigger.dev, or pg_cron) rather than Edge Functions.
