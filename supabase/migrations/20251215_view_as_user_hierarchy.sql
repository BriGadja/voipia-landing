-- Migration: View As User Hierarchy Support
-- Date: 2025-12-15
-- Description: Modifie get_company_agent_hierarchy pour supporter le mode "view as user"
--              Permet aux admins de voir la hiérarchie d'un autre utilisateur

DROP FUNCTION IF EXISTS get_company_agent_hierarchy();
DROP FUNCTION IF EXISTS get_company_agent_hierarchy(UUID);

CREATE OR REPLACE FUNCTION get_company_agent_hierarchy(
  p_view_as_user_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_result jsonb;
  v_is_admin boolean;
  v_effective_user_id uuid;
BEGIN
  v_is_admin := is_admin();

  -- Determine which user's permissions to use
  -- If admin and view_as_user_id is provided, use that user's permissions
  -- Otherwise, use current user's permissions
  IF v_is_admin AND p_view_as_user_id IS NOT NULL THEN
    v_effective_user_id := p_view_as_user_id;
  ELSE
    v_effective_user_id := auth.uid();
  END IF;

  SELECT COALESCE(jsonb_agg(company_data ORDER BY company_data->>'client_name'), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'client_id', c.id,
      'client_name', c.name,
      'industry', c.industry,
      'agents', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'deployment_id', ad.id,
            'deployment_name', ad.name,
            'slug', ad.slug,
            'agent_type_name', at.name,
            'agent_type_display_name', at.display_name,
            'status', ad.status,
            'last_call_at', (
              SELECT MAX(ac.started_at)
              FROM agent_calls ac
              WHERE ac.deployment_id = ad.id
            )
          )
          ORDER BY ad.name
        ), '[]'::jsonb)
        FROM agent_deployments ad
        JOIN agent_types at ON ad.agent_type_id = at.id
        WHERE ad.client_id = c.id
          AND ad.status = 'active'
      )
    ) AS company_data
    FROM clients c
    WHERE (
        -- If admin viewing as self (no p_view_as_user_id), show everything
        (v_is_admin = true AND p_view_as_user_id IS NULL)
        OR
        -- Otherwise, filter by effective user's permissions
        EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.client_id = c.id
            AND ucp.user_id = v_effective_user_id
        )
      )
      AND EXISTS (
        SELECT 1 FROM agent_deployments ad2
        WHERE ad2.client_id = c.id
          AND ad2.status = 'active'
      )
  ) sub;

  RETURN v_result;
END;
$function$;

GRANT EXECUTE ON FUNCTION get_company_agent_hierarchy(UUID) TO authenticated;

COMMENT ON FUNCTION get_company_agent_hierarchy IS 'Returns company-agent hierarchy for sidebar navigation. Admin can pass p_view_as_user_id to see hierarchy from another users perspective.';
