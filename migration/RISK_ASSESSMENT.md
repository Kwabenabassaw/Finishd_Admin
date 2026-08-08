# Risk Assessment

## High Risk Areas

### 1. Moderation Queue Downtime
- **Risk**: Moderation tools are critical for the platform's trust and safety. Any downtime or bugs in the new React dashboard could lead to inappropriate content staying live.
- **Mitigation**: Implement robust Playwright E2E tests for the moderation workflows. Run the Flutter and React dashboards in parallel during a transition period.

### 2. Edge Function Scalability Limits
- **Risk**: The `compute-feed-rankings` Edge Function iterates over videos sequentially. As the app scales towards millions of events, this function will hit Deno timeout limits.
- **Mitigation**: This is an existing backend risk that must be addressed regardless of the frontend migration. Refactor the logic to use Postgres cron (`pg_cron`) or a dedicated queue worker (like Trigger.dev).

### 3. Realtime Connection Leaks
- **Risk**: Improper usage of `useEffect` with Supabase Realtime in React can cause multiple WebSocket connections per client, leading to Supabase connection limits being exhausted.
- **Mitigation**: Create strict custom hooks (`useSupabaseRealtime`) that guarantee channel cleanup on component unmount.

## Medium Risk Areas

### 1. Data Joining Performance
- **Risk**: The current Flutter app fetches lists of data (like comments) and then does a secondary fetch for user profiles. Replicating this in React will lead to N+1 query performance issues.
- **Mitigation**: Ensure the React app utilizes Supabase's foreign key joining syntax (`select('*, profiles(*)')`) to fetch relational data in a single request.

### 2. JWT and RLS Context
- **Risk**: Some Edge functions verify JWTs manually instead of inheriting context via standard PostgREST RLS.
- **Mitigation**: Carefully review authentication headers passed from the Next.js frontend to Edge Functions to ensure they properly identify the admin user.

## Low Risk Areas
- Static dashboard metric displays.
- Settings management.
- Simple CRUD interfaces (e.g., viewing static audit logs).
