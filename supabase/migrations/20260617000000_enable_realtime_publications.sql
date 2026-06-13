-- ============================================================================
-- V3.6 Migration 24: Enable Realtime publications for admin tables
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'creator_videos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.creator_videos;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'creator_applications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.creator_applications;
  END IF;
END $$;
