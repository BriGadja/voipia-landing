-- Migration: Add admin "view as user" functionality
-- Date: 2025-11-27
-- Changes:
--   1. Add get_all_users_for_admin function (admin only)
--   2. Add get_user_client_ids function (admin only)
--
-- These functions allow admins to view the dashboard as any user

-- ============================================================================
-- 1. FUNCTION: get_all_users_for_admin
-- Lists all users with their permissions (admin only)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_users_for_admin()
RETURNS TABLE(
  user_id uuid,
  email text,
  full_name text,
  accessible_clients text[],
  permission_level text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Check if current user is admin (use alias to avoid ambiguity)
  IF NOT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin permission required';
  END IF;

  RETURN QUERY
  SELECT
    u.id as user_id,
    u.email::text,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email)::text as full_name,
    array_agg(DISTINCT c.name ORDER BY c.name)::text[] as accessible_clients,
    max(ucp.permission_level)::text as permission_level
  FROM auth.users u
  INNER JOIN user_client_permissions ucp ON u.id = ucp.user_id
  INNER JOIN clients c ON ucp.client_id = c.id
  GROUP BY u.id, u.email, u.raw_user_meta_data->>'full_name'
  ORDER BY u.email;
END;
$$;

GRANT EXECUTE ON FUNCTION get_all_users_for_admin() TO authenticated;

-- ============================================================================
-- 2. FUNCTION: get_user_client_ids
-- Gets client IDs for a specific user (admin only)
-- Used when an admin wants to view the dashboard as another user
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_client_ids(p_user_id uuid)
RETURNS uuid[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_client_ids uuid[];
BEGIN
  -- Check if current user is admin (use alias to avoid ambiguity)
  IF NOT EXISTS (
    SELECT 1 FROM user_client_permissions ucp_check
    WHERE ucp_check.user_id = auth.uid() AND ucp_check.permission_level = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin permission required';
  END IF;

  -- Get client IDs for the specified user
  SELECT array_agg(ucp.client_id)
  INTO v_client_ids
  FROM user_client_permissions ucp
  WHERE ucp.user_id = p_user_id;

  RETURN COALESCE(v_client_ids, ARRAY[]::uuid[]);
END;
$$;

GRANT EXECUTE ON FUNCTION get_user_client_ids(uuid) TO authenticated;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Test get_all_users_for_admin:
-- SELECT * FROM get_all_users_for_admin();

-- Test get_user_client_ids:
-- SELECT get_user_client_ids('user-uuid-here');
