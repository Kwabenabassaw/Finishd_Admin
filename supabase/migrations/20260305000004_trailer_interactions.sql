-- Migration: Create tables for trailer interactions (likes and comments)
-- Creates: trailer_reactions, trailer_comments

-- 1. Create trailer_reactions table
CREATE TABLE IF NOT EXISTS public.trailer_reactions (
    trailer_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trailer_id, user_id)
);

-- Enable RLS for trailer_reactions
ALTER TABLE public.trailer_reactions ENABLE ROW LEVEL SECURITY;

-- Policies for trailer_reactions
CREATE POLICY "Anyone can view trailer reactions"
    ON public.trailer_reactions FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can add their own trailer reaction"
    ON public.trailer_reactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authenticated users can delete their own trailer reaction"
    ON public.trailer_reactions FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_trailer_reactions_trailer_id ON public.trailer_reactions (trailer_id);
CREATE INDEX IF NOT EXISTS idx_trailer_reactions_user_id ON public.trailer_reactions (user_id);


-- 2. Create trailer_comments table
CREATE TABLE IF NOT EXISTS public.trailer_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trailer_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for trailer_comments
ALTER TABLE public.trailer_comments ENABLE ROW LEVEL SECURITY;

-- Policies for trailer_comments
CREATE POLICY "Anyone can view trailer comments"
    ON public.trailer_comments FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can add their own trailer comment"
    ON public.trailer_comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authenticated users can delete their own trailer comment"
    ON public.trailer_comments FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can update their own trailer comment"
    ON public.trailer_comments FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_trailer_comments_trailer_id ON public.trailer_comments (trailer_id);
CREATE INDEX IF NOT EXISTS idx_trailer_comments_created_at ON public.trailer_comments (created_at DESC);

-- Note: user details (username, avatar) for comments will be joined from public.profiles or auth.users client-side or via a view.
