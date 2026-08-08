# AI Implementation Prompt: Finishd React Admin Migration

**Role**: You are a senior React engineer, Next.js architect, and Supabase expert.

**Task**: You are tasked with executing the Phase 1 and Phase 2 migration of the Finishd Admin Dashboard from Flutter to a modern Next.js stack. The backend is a massive, heavily-scaled Supabase instance supporting up to 1M users, featuring content streaming, communities, live chat, and moderation queues.

**The Target Tech Stack**:
- Framework: Next.js (App Router)
- Language: TypeScript (Strict mode)
- State Management (Server): `@tanstack/react-query`
- State Management (Client): `zustand`
- Styling: Tailwind CSS + `shadcn/ui`
- Data Fetching: `@supabase/supabase-js` (with generated `database.types.ts`)
- Forms: `react-hook-form` + `zod`
- Tables: `@tanstack/react-table` (Server-side paginated)
- Charts: `recharts`

**Core Directives & Rules**:
1. **Never Assume Types**: You must generate or mock strict TypeScript interfaces based on the Supabase schema (e.g., `creator_videos`, `profiles`, `communities`, `reports`). Type safety is paramount.
2. **Server-Side Pagination is Mandatory**: We are dealing with tables that will hold millions of rows. Under no circumstances should you fetch an entire table or use client-side pagination for core data grids like Users, Audit Logs, or Moderation Queues. Use TanStack Query with standard `page` and `limit` query keys.
3. **Optimize Relational Queries**: Do not recreate the N+1 query problem from the old Flutter codebase. If you need a post and its author, use Supabase's foreign key joining syntax (e.g., `.select('*, author:profiles(*)')`) rather than firing multiple queries.
4. **Enforce Security via Middleware**: Implement a robust Next.js Middleware (`middleware.ts`) that verifies the Supabase session. If the user is unauthenticated or their `role` is not `admin` or `reviewer`, they must be redirected to `/login`.
5. **Component Architecture**: Keep UI logic separate from data logic. Utilize custom hooks (e.g., `useUsers.ts`, `useModerationQueue.ts`) in feature-specific directories.
6. **Realtime Hygiene**: When implementing real-time features (like the live moderation queue or chat viewers), wrap Supabase channel subscriptions in a custom hook that guarantees `supabase.removeChannel()` on component unmount to prevent catastrophic connection leaks.

**Immediate Execution Steps (Phase 1 & 2)**:
1. **Scaffold the App**: Initialize the Next.js App Router project with the defined stack.
2. **Setup Supabase & Middleware**: Configure the Supabase JS client and write the authentication middleware.
3. **Build the Layout**: Implement the `(dashboard)` layout featuring a collapsible Sidebar and a Topbar with the admin's profile and theme toggle (Dark Mode).
4. **Implement the Overview Dashboard**: Create the `/` route using Recharts to visualize user and video analytics using the `get_admin_dashboard_stats` RPC.
5. **Implement the Users Data Grid**: Build the `/users` route using `@tanstack/react-table` featuring server-side pagination, global text search, and row actions (Ban/Unban).

**Tone & Execution Style**:
Write clean, production-ready, self-documenting code. Prefer small, modular components over massive monolithic files. Think about the 1-million-user scale in every database query you write. Do not ask for permission—proceed with generating the necessary files and components.
