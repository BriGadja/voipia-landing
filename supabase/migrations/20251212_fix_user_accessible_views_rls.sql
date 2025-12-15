-- Migration: Fix v_user_accessible_clients and v_user_accessible_agents to filter by auth.uid()
-- Date: 2025-12-12
-- Changes: Add WHERE clause to filter by current authenticated user

-- Drop and recreate v_user_accessible_clients with auth.uid() filter
DROP VIEW IF EXISTS v_user_accessible_clients;

CREATE VIEW v_user_accessible_clients AS
SELECT
    c.id AS client_id,
    c.name AS client_name,
    c.industry,
    ucp.user_id,
    ucp.permission_level,
    count(DISTINCT ad.id) AS total_agents,
    count(DISTINCT ad.id) FILTER (WHERE ad.status = 'active'::text) AS active_agents,
    count(DISTINCT at.name) AS agent_types_count,
    array_agg(DISTINCT at.display_name) FILTER (WHERE at.display_name IS NOT NULL) AS agent_types_list
FROM clients c
JOIN user_client_permissions ucp ON c.id = ucp.client_id
LEFT JOIN agent_deployments ad ON c.id = ad.client_id
LEFT JOIN agent_types at ON ad.agent_type_id = at.id
WHERE ucp.user_id = auth.uid()  -- CRITICAL: Filter by current authenticated user
GROUP BY c.id, c.name, c.industry, ucp.user_id, ucp.permission_level
ORDER BY c.name;

-- Grant access to the view
GRANT SELECT ON v_user_accessible_clients TO authenticated;

-- Drop and recreate v_user_accessible_agents with auth.uid() filter
DROP VIEW IF EXISTS v_user_accessible_agents;

CREATE VIEW v_user_accessible_agents AS
SELECT
    ad.id AS deployment_id,
    ad.name AS deployment_name,
    ad.slug,
    c.id AS client_id,
    c.name AS client_name,
    at.id AS agent_type_id,
    at.name AS agent_type_name,
    at.display_name AS agent_display_name,
    ad.status AS deployment_status,
    ucp.user_id,
    ucp.permission_level,
    (
        SELECT ac.started_at
        FROM agent_calls ac
        WHERE ac.deployment_id = ad.id
        ORDER BY ac.started_at DESC
        LIMIT 1
    ) AS last_call_at,
    (
        SELECT COUNT(*)
        FROM agent_calls ac
        WHERE ac.deployment_id = ad.id
        AND ac.started_at >= NOW() - INTERVAL '30 days'
    )::integer AS total_calls_last_30d
FROM agent_deployments ad
JOIN clients c ON ad.client_id = c.id
JOIN agent_types at ON ad.agent_type_id = at.id
JOIN user_client_permissions ucp ON c.id = ucp.client_id
WHERE ucp.user_id = auth.uid()  -- CRITICAL: Filter by current authenticated user
ORDER BY c.name, ad.name;

-- Grant access to the view
GRANT SELECT ON v_user_accessible_agents TO authenticated;
