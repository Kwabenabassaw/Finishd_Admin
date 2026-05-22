# Flutter Frontend Architecture Analysis

## Overview
The Finishd Admin dashboard is built using Flutter Web (`finishd_admin`), utilizing `provider` for state management/dependency injection, `go_router` for routing, and the `supabase_flutter` SDK for backend connectivity.

## Architecture Patterns

### Routing
- Handled by `go_router` (typically defined in `main.dart` or a routing core file).
- The layout is composed of a shell (`admin_shell.dart`) containing a `sidebar.dart` and `top_bar.dart`.

### State Management & Dependency Injection
- `Provider` is used heavily, but mostly as a simple Dependency Injection container (e.g., providing `AdminRepository` and `SupabaseService` to the widget tree) rather than complex reactive state streams.
- Component state is mostly managed locally inside `StatefulWidget` classes (e.g. `setState(() => _isLoading = true)`).
- This is a brittle approach for large-scale dashboards, leading to duplicate data fetching and a lack of proper caching.

### Services Layer (`lib/core/`)
- `SupabaseService`: A wrapper over `SupabaseClient` that primarily executes database RPC calls (e.g., `get_admin_dashboard_stats()`).
- `AdminRepository`: Acts as an intermediary between the UI and `SupabaseService`. It orchestrates logic, formats payloads, and enforces type casting (e.g., parsing BigInt community IDs).

### Feature Modules (`lib/features/`)
The application is modularized by feature. Key modules include:
- `analytics`, `announcements`, `applications`, `auth`, `communities`, `creators`, `dashboard`, `deeplinks`, `feed`, `logs`, `ml`, `moderation`, `reports`, `settings`, `user_reports`, `users`.
- This structure translates perfectly to a React route/feature-based directory structure.

## Technical Debt & Scalability Limits
1. **Local State for Data Fetching**: Heavy reliance on `StatefulWidget`'s `initState` and `setState` for fetching data. There is no central caching or invalidation strategy (like React Query/TanStack Query would provide).
2. **N+1 Query Problems in UI**: In `AdminRepository.dart`, functions like `getCommunityPosts` and `getCommunityComments` fetch posts, then manually extract author IDs, and execute a second query to fetch user profiles. This data joining should be handled by a Supabase View or joined query instead of in the Dart frontend.
3. **Type Safety Workarounds**: Hand-parsing String to `int.parse(communityId)` to satisfy Postgres BIGINT types is error-prone. A typed framework (TypeScript) with generated Supabase types would solve this.
4. **Data Grid Performance**: The use of standard Flutter tables (`DataTable2`) can struggle with large datasets without explicit virtualization controls.
