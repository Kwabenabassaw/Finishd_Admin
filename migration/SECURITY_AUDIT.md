# Security & Auth Audit

## Authentication Flow
- **Current Setup**: Uses Supabase Auth (`supabase_flutter`). The admin dashboard requires users to be authenticated.
- **Admin Validation**: Validation occurs primarily through Role-Based Access Control (RBAC) enforced by PostgreSQL Row Level Security (RLS) policies.
- **Role Assignment**: Profiles have a `role` column (`user`, `creator`, `reviewer`, `admin`).

## Security Risks & Analysis
1. **Frontend Role Leaking**: The frontend `AdminRepository` often relies on the database to throw permission errors rather than proactively hiding UI elements. While technically secure (the backend rejects unauthorized requests), the UX suffers, and it exposes the existence of features to non-admins.
2. **Missing Edge Function RLS Context**: The `broadcast-announcement` function manually validates the JWT, whereas standard PostgREST calls automatically enforce RLS. Ensure that all Edge Functions correctly instantiate the Supabase client using the Authorization header to inherit user context.
3. **Admin Escalation Risks**: Updating `profiles.role` must be heavily guarded. The `creator-application-review` uses the Service Role Key to bypass RLS to update a profile to `creator`. This is correct, but we must ensure no RPC allows arbitrary role updates.
4. **Data Overfetching**: As seen in the architecture audit, fetching lists of posts and then lists of users separately can leak user data if not properly filtered.

## Realtime Systems Analysis
(Documented in REALTIME_SYSTEMS.md)
