-- ============================================================================
-- V3.5 Migration 23: Dashboard, Creator, and Community Stats Updates
-- ============================================================================

-- ── Update get_admin_dashboard_stats RPC ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_dau INT;
  v_mau INT;
  v_new_users INT;
  v_uploads INT;
  v_pending_reports INT;
  v_total_videos INT;
  v_total_views INT;
  v_total_communities INT;
  v_total_creators INT;
BEGIN
  -- Daily Active Users (computed from interactions + events today)
  SELECT COUNT(DISTINCT user_id) INTO v_dau 
  FROM (
    SELECT user_id FROM public.video_interactions WHERE updated_at::date = CURRENT_DATE
    UNION
    SELECT user_id FROM public.analytics_events WHERE created_at::date = CURRENT_DATE
  ) active_users;

  -- Monthly Active Users (computed from interactions + events last 30 days)
  SELECT COUNT(DISTINCT user_id) INTO v_mau 
  FROM (
    SELECT user_id FROM public.video_interactions WHERE updated_at >= CURRENT_DATE - INTERVAL '30 days'
    UNION
    SELECT user_id FROM public.analytics_events WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  ) active_users_30;

  -- New Users Today
  SELECT COUNT(*) INTO v_new_users FROM public.profiles WHERE created_at::date = CURRENT_DATE;

  -- Videos Uploaded Today
  SELECT COUNT(*) INTO v_uploads FROM public.creator_videos WHERE created_at::date = CURRENT_DATE;

  -- Pending Reports
  SELECT COUNT(*) INTO v_pending_reports FROM public.reports WHERE status = 'pending';

  -- Total non-deleted videos
  SELECT COUNT(*)::int INTO v_total_videos FROM public.creator_videos WHERE deleted_at IS NULL;

  -- Total views across all creator videos
  SELECT COALESCE(SUM(view_count), 0)::int INTO v_total_views FROM public.creator_videos WHERE deleted_at IS NULL;

  -- Total communities
  SELECT COUNT(*)::int INTO v_total_communities FROM public.communities;

  -- Total approved creators
  SELECT COUNT(*)::int INTO v_total_creators FROM public.profiles WHERE role = 'creator' AND creator_status = 'approved';

  RETURN jsonb_build_object(
    'daily_active_users', COALESCE(v_dau, 0),
    'monthly_active_users', COALESCE(v_mau, 0),
    'new_users_today', COALESCE(v_new_users, 0),
    'videos_uploaded_today', COALESCE(v_uploads, 0),
    'pending_reports', COALESCE(v_pending_reports, 0),
    'total_videos', COALESCE(v_total_videos, 0),
    'total_video_views', COALESCE(v_total_views, 0),
    'total_communities', COALESCE(v_total_communities, 0),
    'total_creators', COALESCE(v_total_creators, 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── New get_approved_creators RPC ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_approved_creators()
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ,
  stats JSONB
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    COALESCE(p.first_name || ' ' || p.last_name, p.username) AS display_name,
    p.avatar_url,
    p.created_at,
    jsonb_build_object(
      'followers', (SELECT COUNT(*)::int FROM public.follows f WHERE f.following_id = p.id),
      'videos', (SELECT COUNT(*)::int FROM public.creator_videos cv WHERE cv.creator_id = p.id AND cv.status = 'approved' AND cv.deleted_at IS NULL),
      'engagement', (
        SELECT COALESCE(SUM(cv.like_count + cv.comment_count + cv.view_count), 0)::int
        FROM public.creator_videos cv
        WHERE cv.creator_id = p.id AND cv.status = 'approved' AND cv.deleted_at IS NULL
      )
    ) AS stats
  FROM public.profiles p
  WHERE p.role = 'creator' AND p.creator_status = 'approved'
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ── New get_communities RPC ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_communities()
RETURNS TABLE (
  id BIGINT,
  show_id INT,
  title TEXT,
  poster_path TEXT,
  media_type TEXT,
  member_count INT,
  post_count INT,
  status TEXT,
  toxicity_score NUMERIC,
  posts_per_day NUMERIC
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.show_id,
    c.title,
    c.poster_path,
    c.media_type,
    c.member_count,
    c.post_count,
    c.status,
    c.toxicity_score,
    COALESCE(
      (SELECT COUNT(*)::numeric / 7.0 FROM public.community_posts cp WHERE cp.community_id = c.id AND cp.created_at >= now() - INTERVAL '7 days'),
      0.0
    ) AS posts_per_day
  FROM public.communities c
  ORDER BY c.member_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
