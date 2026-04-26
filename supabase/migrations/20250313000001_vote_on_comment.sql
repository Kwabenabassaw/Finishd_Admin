-- ============================================================================
-- Migration: Add vote_on_comment RPC function
-- Mirrors vote_on_post logic for community comments
-- ============================================================================

CREATE OR REPLACE FUNCTION public.vote_on_comment(p_comment_id UUID, p_vote INT)
RETURNS VOID AS $$
DECLARE
  v_uid UUID; v_current INT; v_new INT;
  v_up_d INT := 0; v_down_d INT := 0;
BEGIN
  v_uid := auth.uid();

  -- Get current vote
  SELECT vote INTO v_current FROM public.comment_votes WHERE user_id = v_uid AND comment_id = p_comment_id;
  IF v_current IS NULL THEN v_current := 0; END IF;

  -- Toggle logic: same vote = remove, different vote = switch
  v_new := CASE WHEN p_vote = v_current THEN 0 ELSE p_vote END;
  IF v_new = v_current THEN RETURN; END IF;

  -- Calculate deltas
  IF v_current =  1 THEN v_up_d   := v_up_d   - 1; END IF;
  IF v_current = -1 THEN v_down_d := v_down_d - 1; END IF;
  IF v_new     =  1 THEN v_up_d   := v_up_d   + 1; END IF;
  IF v_new     = -1 THEN v_down_d := v_down_d + 1; END IF;

  -- Update or delete the vote record
  IF v_new = 0 THEN
    DELETE FROM public.comment_votes WHERE user_id = v_uid AND comment_id = p_comment_id;
  ELSE
    INSERT INTO public.comment_votes (user_id, comment_id, vote) VALUES (v_uid, p_comment_id, v_new)
    ON CONFLICT (user_id, comment_id) DO UPDATE SET vote = v_new, created_at = now();
  END IF;

  -- Update the comment's denormalized counters
  UPDATE public.community_comments SET
    upvotes = upvotes + v_up_d,
    downvotes = downvotes + v_down_d
  WHERE id = p_comment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
