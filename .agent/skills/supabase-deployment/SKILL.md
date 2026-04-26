---
name: supabase-deployment
description: Deploys Supabase database migrations and Edge Functions to the linked project. Use when the user asks to "push", "deploy", or "upload" database changes or functions.
---

# Supabase Deployment Skill

## When to use this skill
- When the user wants to push new migrations to a remote Supabase project.
- When the user wants to deploy Edge Functions.
- When the user mentions "uploading the database" or "deploying the backend".

## Prerequisites
- Supabase CLI must be installed (`brew install supabase/tap/supabase` or `npm install supabase`).
- The project must be linked (`supabase link --project-ref <project-id>`).

## Workflow

### 1. Pre-deployment Validation
Before pushing any changes, verify the environment and connection:
- [ ] Run `supabase status` to check if the CLI is initialized.
- [ ] Check `supabase/migrations/` for the files to be pushed.
- [ ] Check `supabase/functions/` for the functions to be deployed.

### 2. Database Migration Deployment
To push migrations to the linked project:
```bash
# Push all local migrations that haven't been applied yet
supabase db push
```
*Note: If the user wants to reset or force push, ask for confirmation first.*

### 3. Edge Function Deployment
To deploy all functions:
```bash
supabase functions deploy
```
To deploy a specific function (e.g., `broadcast-announcement`):
```bash
supabase functions deploy broadcast-announcement
```

### 4. Secrets Management
If functions require environment variables (like `FIREBASE_SERVICE_ACCOUNT_B64`):
```bash
# List secrets
supabase secrets list

# Set a secret
supabase secrets set KEY=VALUE
```

## Safety Rules
1. **Never** run `supabase db reset` on a production project unless explicitly instructed.
2. **Always** check for linting errors in migrations before pushing.
3. If `supabase link` is required, ask the user for their **Project Reference ID**.

## Troubleshooting
- **Migration Conflict**: If the remote database has changes not in the local migration files, run `supabase db pull` first or resolve conflicts manually.
- **Function Build Failure**: Ensure `deno` is configured correctly if working locally, or check the logs using `supabase functions logs <name>`.
