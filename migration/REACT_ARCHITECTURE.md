# React Architecture Proposal

## Core Stack
- **Framework**: Next.js (App Router). Best for routing, API routes (if needed to mask Edge Functions), and SEO/performance.
- **Language**: TypeScript (Strict mode). Essential for maintaining complex Supabase schema types.
- **State Management (Server)**: `@tanstack/react-query`. Replaces `Provider` + `setState` for fetching, caching, and invalidating database calls.
- **State Management (Client)**: `zustand` for lightweight global state (e.g., sidebar toggles, current active moderation item).
- **Styling**: Tailwind CSS + `shadcn/ui` for rapid, accessible, and customizable admin components.
- **Forms**: `react-hook-form` + `zod` for robust validation (critical for moderation and broadcast inputs).
- **Tables**: `@tanstack/react-table` for highly performant, virtualized data grids necessary for large user and log datasets.

## Folder Structure Proposal
```
src/
├── app/                  # Next.js App Router (Pages & Layouts)
│   ├── (auth)/           # Login/Logout routes
│   ├── (dashboard)/      # Protected admin routes
│   │   ├── users/
│   │   ├── moderation/
│   │   ├── communities/
│   │   └── ...
├── components/           # Reusable UI components
│   ├── ui/               # shadcn/ui components
│   ├── data-table/       # Complex table implementations
│   └── forms/            # Reusable form elements
├── lib/                  # Utilities and configs
│   ├── supabase/         # Supabase client instantiation
│   ├── utils.ts          # Tailwind merge utilities
│   └── database.types.ts # Generated Supabase types
├── features/             # Domain-specific logic
│   ├── users/
│   │   ├── api/          # TanStack Query hooks (e.g., useUsers.ts)
│   │   └── components/   # User-specific components
│   ├── moderation/
│   └── ...
└── store/                # Zustand stores
```

## Data Fetching & Caching Strategy
- Use `@supabase/supabase-js` alongside `@tanstack/react-query`.
- **Query Keys**: Standardize query keys (e.g., `['users', { page, search }]`).
- **Invalidation**: On mutation (e.g., banning a user), invalidate the relevant query key to automatically refetch.

## Security & Route Protection
- Use Next.js Middleware (`middleware.ts`) to intercept routes and verify the Supabase session.
- If the user is not authenticated or lacks the `admin` role, redirect them to the `/login` page.

## Realtime Architecture
- Create a custom hook `useSupabaseRealtime` that accepts a table name and callback.
- Ensure the `useEffect` cleanup function calls `supabase.removeChannel()` to prevent memory and subscription leaks.
