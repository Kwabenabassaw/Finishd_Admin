-- ============================================================================
-- RPCs for DAU/MAU Metrics
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_dau_mau_stats(p_days INT)
RETURNS TABLE (
  date DATE,
  dau INT,
  mau INT
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
  user_activity AS (
    SELECT updated_at::date as activity_date, user_id FROM public.video_interactions
    UNION
    SELECT created_at::date as activity_date, user_id FROM public.analytics_events
  )
  SELECT 
    ds.dt as date,
    COALESCE((SELECT COUNT(DISTINCT ua.user_id)::int FROM user_activity ua WHERE ua.activity_date = ds.dt), 0) as dau,
    COALESCE((SELECT COUNT(DISTINCT ua.user_id)::int FROM user_activity ua WHERE ua.activity_date BETWEEN ds.dt - INTERVAL '30 days' AND ds.dt), 0) as mau
  FROM date_series ds
  ORDER BY ds.dt ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
