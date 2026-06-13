-- ============================================================================
-- V3.7 Migration 25: RPCs for Platform Analytics Charts
-- ============================================================================

-- 1. Daily Active Users (DAU) over N days
CREATE OR REPLACE FUNCTION public.get_daily_active_users(p_days INT)
RETURNS TABLE (
  date DATE,
  active_users INT
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT (CURRENT_DATE - i)::DATE as dt
    FROM generate_series(0, p_days - 1) i
  ),
  active_users_by_day AS (
    SELECT updated_at::date as active_date, user_id
    FROM public.video_interactions
    WHERE updated_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    UNION
    SELECT created_at::date as active_date, user_id
    FROM public.analytics_events
    WHERE created_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
  )
  SELECT 
    ds.dt as date,
    COALESCE(COUNT(DISTINCT aud.user_id)::int, 0) as active_users
  FROM date_series ds
  LEFT JOIN active_users_by_day aud ON aud.active_date = ds.dt
  GROUP BY ds.dt
  ORDER BY ds.dt ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Average Video Completion Percentage (%) over N days
CREATE OR REPLACE FUNCTION public.get_daily_video_completion(p_days INT)
RETURNS TABLE (
  date DATE,
  avg_completion INT
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT (CURRENT_DATE - i)::DATE as dt
    FROM generate_series(0, p_days - 1) i
  ),
  completion_by_day AS (
    SELECT 
      vds.date as event_date,
      SUM(sum_completion_pct) as total_pct,
      SUM(total_views) as total_views
    FROM public.video_daily_stats vds
    WHERE vds.date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    GROUP BY vds.date
  )
  SELECT 
    ds.dt as date,
    COALESCE(CASE WHEN cbd.total_views > 0 THEN (cbd.total_pct / cbd.total_views * 100)::int ELSE 0 END, 0) as avg_completion
  FROM date_series ds
  LEFT JOIN completion_by_day cbd ON cbd.event_date = ds.dt
  GROUP BY ds.dt, cbd.total_views, cbd.total_pct
  ORDER BY ds.dt ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 3. Average Scroll Depth (px) from analytics_events
CREATE OR REPLACE FUNCTION public.get_daily_scroll_depth(p_days INT)
RETURNS TABLE (
  date DATE,
  avg_scroll_depth INT
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT (CURRENT_DATE - i)::DATE as dt
    FROM generate_series(0, p_days - 1) i
  ),
  scroll_events AS (
    SELECT 
      created_at::date as event_date,
      (parameters->>'depth_px')::numeric as depth
    FROM public.analytics_events
    WHERE event_name = 'scroll_depth'
      AND created_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
  )
  SELECT 
    ds.dt as date,
    COALESCE(AVG(se.depth)::int, 0) as avg_scroll_depth
  FROM date_series ds
  LEFT JOIN scroll_events se ON se.event_date = ds.dt
  GROUP BY ds.dt
  ORDER BY ds.dt ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 4. Community Engagement (Posts + Comments + Joins) over N days
CREATE OR REPLACE FUNCTION public.get_daily_community_engagement(p_days INT)
RETURNS TABLE (
  date DATE,
  engagement_count INT
) AS $$
BEGIN
  -- Check if caller is admin/reviewer
  IF NOT EXISTS (SELECT 1 FROM public.profiles admin_chk WHERE admin_chk.id = auth.uid() AND admin_chk.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT (CURRENT_DATE - i)::DATE as dt
    FROM generate_series(0, p_days - 1) i
  ),
  daily_posts AS (
    SELECT created_at::date as dt, COUNT(*)::int as cnt
    FROM public.community_posts
    WHERE created_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    GROUP BY created_at::date
  ),
  daily_comments AS (
    SELECT created_at::date as dt, COUNT(*)::int as cnt
    FROM public.community_comments
    WHERE created_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    GROUP BY created_at::date
  ),
  daily_joins AS (
    SELECT joined_at::date as dt, COUNT(*)::int as cnt
    FROM public.community_members
    WHERE joined_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    GROUP BY joined_at::date
  )
  SELECT 
    ds.dt as date,
    (COALESCE(dp.cnt, 0) + COALESCE(dc.cnt, 0) + COALESCE(dj.cnt, 0))::int as engagement_count
  FROM date_series ds
  LEFT JOIN daily_posts dp ON dp.dt = ds.dt
  LEFT JOIN daily_comments dc ON dc.dt = ds.dt
  LEFT JOIN daily_joins dj ON dj.dt = ds.dt
  GROUP BY ds.dt, dp.cnt, dc.cnt, dj.cnt
  ORDER BY ds.dt ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
