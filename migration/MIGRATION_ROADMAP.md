# Migration Roadmap & Plan

## Phase 1: Bootstrapping & Foundation
1. Initialize Next.js project with TypeScript, Tailwind, and App Router.
2. Setup `shadcn/ui` and configure global themes (including dark mode).
3. Setup Supabase JS client and generate database types (`database.types.ts`).
4. Implement Next.js Middleware for secure route protection (Admin only).
5. Build the authentication page and basic layout shell (Sidebar, Topbar).

## Phase 2: Core Read-Only Features
1. **Dashboard**: Implement the overview page using Recharts and TanStack Query.
2. **Users**: Implement the Users data table with server-side pagination and search.
3. **Audit Logs**: Implement the logs viewer table.

## Phase 3: Moderation & Actionable Workflows
1. **Moderation Queue**: Build the UI to review pending videos (requires a performant video player component).
2. **Reports**: Build the report resolution workflow.
3. **Communities**: Implement the nested routing for Communities -> Posts -> Comments -> Members.

## Phase 4: Edge Functions & Refactoring
1. Refactor the Flutter `AdminRepository` manual joins into native Supabase foreign key select queries.
2. Optimize Edge Functions (e.g., array aggregations, feed rankings) to ensure backend scalability.
3. Implement the Announcements broadcast form, ensuring strict validation before hitting the Edge Function.

## Phase 5: Realtime & Polish
1. Implement real-time subscriptions for the moderation queue.
2. Add end-to-end (E2E) testing for critical admin workflows (banning users, approving videos) using Playwright.
3. Setup CI/CD pipeline (e.g., GitHub Actions to Vercel).

# Risk Assessment

- **High Risk**: Moving the active moderation tools. If the new dashboard goes down, moderation halts. **Mitigation**: Run both dashboards in parallel during the rollout phase.
- **Medium Risk**: Edge Function timeouts. As the platform scales to 1M users, cron jobs will fail if not optimized. **Mitigation**: Prioritize backend refactoring outlined in `PERFORMANCE_ANALYSIS.md`.
- **Low Risk**: Simple CRUD operations (Settings, Analytics).
