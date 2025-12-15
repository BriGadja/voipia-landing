-- ============================================================================
-- Migration: Dashboard Restructure - Navigation et Consommation
-- Date: 2025-12-15
-- Description:
--   1. get_company_agent_hierarchy() - Hierarchie entreprise/agent pour sidebar
--   2. get_user_consumption_metrics() - Metriques consommation (sans marge)
--   3. get_admin_billing_summary() - Resume facturation admin (avec marge)
--
-- SECURITE:
--   - Toutes les fonctions utilisent SECURITY DEFINER SET search_path = public
--   - Fonctions admin verifient is_admin() en premier
--   - Fonctions utilisateur filtrent par user_client_permissions + auth.uid()
--   - JAMAIS exposer: provider_cost, margin, stt_cost, tts_cost, llm_cost
-- ============================================================================

-- ============================================================================
-- PARTIE 1: get_company_agent_hierarchy()
-- Retourne la hierarchie entreprise -> agents pour la navigation sidebar
-- Admin: voit TOUTES les entreprises
-- Utilisateur: voit uniquement ses entreprises (via user_client_permissions)
-- ============================================================================

DROP FUNCTION IF EXISTS get_company_agent_hierarchy();

CREATE OR REPLACE FUNCTION get_company_agent_hierarchy()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_is_admin boolean;
BEGIN
  -- Verifier si l'utilisateur est admin
  v_is_admin := is_admin();

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
        -- Admin voit toutes les entreprises
        v_is_admin = true
        OR
        -- Non-admin voit uniquement ses entreprises
        EXISTS (
          SELECT 1 FROM user_client_permissions ucp
          WHERE ucp.client_id = c.id
            AND ucp.user_id = auth.uid()
        )
      )
      -- Uniquement les entreprises avec au moins un agent actif
      AND EXISTS (
        SELECT 1 FROM agent_deployments ad2
        WHERE ad2.client_id = c.id
          AND ad2.status = 'active'
      )
  ) sub;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_company_agent_hierarchy() TO authenticated;
GRANT EXECUTE ON FUNCTION get_company_agent_hierarchy() TO service_role;

COMMENT ON FUNCTION get_company_agent_hierarchy() IS
'Retourne la hierarchie entreprise->agents pour la navigation sidebar.
Admin: voit TOUTES les entreprises.
Utilisateur: voit uniquement ses entreprises (via user_client_permissions).
Filtre: uniquement les agents actifs.';


-- ============================================================================
-- PARTIE 2: get_user_consumption_metrics()
-- Metriques de consommation pour les utilisateurs (SANS marge)
-- SECURITE: NE retourne JAMAIS provider_cost, margin, margin_percentage
-- ============================================================================

DROP FUNCTION IF EXISTS get_user_consumption_metrics(date, date, uuid);

CREATE OR REPLACE FUNCTION get_user_consumption_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_accessible_client_ids uuid[];
BEGIN
  -- Recuperer les IDs des clients accessibles par l'utilisateur
  SELECT ARRAY_AGG(DISTINCT ucp.client_id)
  INTO v_accessible_client_ids
  FROM user_client_permissions ucp
  WHERE ucp.user_id = auth.uid()
    AND (p_client_id IS NULL OR ucp.client_id = p_client_id);

  -- Si aucun client accessible, retourner des valeurs vides
  IF v_accessible_client_ids IS NULL OR array_length(v_accessible_client_ids, 1) IS NULL THEN
    RETURN jsonb_build_object(
      'current_period', jsonb_build_object(
        'total_minutes', 0,
        'total_seconds', 0,
        'total_sms_segments', 0,
        'total_emails', 0,
        'total_calls', 0,
        'answered_calls', 0,
        'appointments_scheduled', 0,
        'total_cost', 0,
        'call_cost', 0,
        'sms_cost', 0,
        'email_cost', 0
      ),
      'pricing', jsonb_build_object(
        'avg_price_per_minute', 0,
        'avg_price_per_sms', 0,
        'avg_price_per_email', 0
      ),
      'by_agent', '[]'::jsonb
    );
  END IF;

  -- Calculer les metriques de consommation
  WITH call_metrics AS (
    SELECT
      ad.id AS deployment_id,
      ad.name AS deployment_name,
      at.name AS agent_type_name,
      c.name AS client_name,
      ad.cost_per_min,
      ad.cost_per_sms,
      ad.cost_per_email,
      COUNT(ac.id) AS total_calls,
      COUNT(ac.id) FILTER (WHERE ac.outcome NOT IN ('voicemail', 'no_answer', 'busy', 'call_failed', 'invalid_number', 'error', 'canceled', 'rejected') AND ac.outcome IS NOT NULL) AS answered_calls,
      COUNT(ac.id) FILTER (WHERE ac.outcome = 'appointment_scheduled') AS appointments_scheduled,
      COALESCE(SUM(ac.duration_seconds), 0) AS total_seconds,
      -- Calcul du cout client (PAS provider cost)
      COALESCE(SUM(ac.duration_seconds / 60.0 * ad.cost_per_min), 0) AS call_cost
    FROM agent_deployments ad
    JOIN agent_types at ON ad.agent_type_id = at.id
    JOIN clients c ON ad.client_id = c.id
    LEFT JOIN agent_calls ac ON ad.id = ac.deployment_id
      AND ac.started_at >= p_start_date
      AND ac.started_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'
    GROUP BY ad.id, ad.name, at.name, c.name, ad.cost_per_min, ad.cost_per_sms, ad.cost_per_email
  ),
  sms_metrics AS (
    SELECT
      ad.id AS deployment_id,
      COUNT(asms.id) AS total_sms,
      COALESCE(SUM(asms.num_segments), COUNT(asms.id)) AS total_segments,
      -- Utiliser billed_cost (cout client) PAS provider_cost
      COALESCE(SUM(asms.billed_cost), 0) AS sms_cost
    FROM agent_deployments ad
    LEFT JOIN agent_sms asms ON ad.id = asms.deployment_id
      AND asms.sent_at >= p_start_date
      AND asms.sent_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'
    GROUP BY ad.id
  ),
  email_metrics AS (
    SELECT
      ad.id AS deployment_id,
      COUNT(ae.id) AS total_emails,
      -- Utiliser billed_cost (cout client) PAS provider_cost
      COALESCE(SUM(ae.billed_cost), 0) AS email_cost
    FROM agent_deployments ad
    LEFT JOIN agent_emails ae ON ad.id = ae.deployment_id
      AND ae.sent_at >= p_start_date
      AND ae.sent_at < p_end_date + INTERVAL '1 day'
    WHERE ad.client_id = ANY(v_accessible_client_ids)
      AND ad.status = 'active'
    GROUP BY ad.id
  ),
  combined AS (
    SELECT
      cm.deployment_id,
      cm.deployment_name,
      cm.agent_type_name,
      cm.client_name,
      cm.cost_per_min,
      cm.cost_per_sms,
      cm.cost_per_email,
      cm.total_calls,
      cm.answered_calls,
      cm.appointments_scheduled,
      cm.total_seconds,
      cm.call_cost,
      COALESCE(sm.total_sms, 0) AS total_sms,
      COALESCE(sm.total_segments, 0) AS total_segments,
      COALESCE(sm.sms_cost, 0) AS sms_cost,
      COALESCE(em.total_emails, 0) AS total_emails,
      COALESCE(em.email_cost, 0) AS email_cost
    FROM call_metrics cm
    LEFT JOIN sms_metrics sm ON cm.deployment_id = sm.deployment_id
    LEFT JOIN email_metrics em ON cm.deployment_id = em.deployment_id
  ),
  totals AS (
    SELECT
      SUM(total_calls) AS total_calls,
      SUM(answered_calls) AS answered_calls,
      SUM(appointments_scheduled) AS appointments_scheduled,
      SUM(total_seconds) AS total_seconds,
      SUM(call_cost) AS call_cost,
      SUM(total_segments) AS total_segments,
      SUM(sms_cost) AS sms_cost,
      SUM(total_emails) AS total_emails,
      SUM(email_cost) AS email_cost
    FROM combined
  )
  SELECT jsonb_build_object(
    'current_period', jsonb_build_object(
      'total_minutes', ROUND((t.total_seconds / 60.0)::numeric, 2),
      'total_seconds', t.total_seconds,
      'total_sms_segments', t.total_segments,
      'total_emails', t.total_emails,
      'total_calls', t.total_calls,
      'answered_calls', t.answered_calls,
      'appointments_scheduled', t.appointments_scheduled,
      'total_cost', ROUND((t.call_cost + t.sms_cost + t.email_cost)::numeric, 2),
      'call_cost', ROUND(t.call_cost::numeric, 2),
      'sms_cost', ROUND(t.sms_cost::numeric, 2),
      'email_cost', ROUND(t.email_cost::numeric, 2)
    ),
    'pricing', jsonb_build_object(
      'avg_price_per_minute', CASE
        WHEN t.total_seconds > 0
        THEN ROUND((t.call_cost / (t.total_seconds / 60.0))::numeric, 4)
        ELSE 0
      END,
      'avg_price_per_sms', CASE
        WHEN t.total_segments > 0
        THEN ROUND((t.sms_cost / t.total_segments)::numeric, 4)
        ELSE 0
      END,
      'avg_price_per_email', CASE
        WHEN t.total_emails > 0
        THEN ROUND((t.email_cost / t.total_emails)::numeric, 4)
        ELSE 0
      END
    ),
    'by_agent', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'deployment_id', c.deployment_id,
          'deployment_name', c.deployment_name,
          'agent_type_name', c.agent_type_name,
          'client_name', c.client_name,
          'total_minutes', ROUND((c.total_seconds / 60.0)::numeric, 2),
          'total_seconds', c.total_seconds,
          'total_sms_segments', c.total_segments,
          'total_emails', c.total_emails,
          'total_calls', c.total_calls,
          'answered_calls', c.answered_calls,
          'appointments_scheduled', c.appointments_scheduled,
          'total_cost', ROUND((c.call_cost + c.sms_cost + c.email_cost)::numeric, 2),
          'price_per_minute', COALESCE(c.cost_per_min, 0),
          'price_per_sms', COALESCE(c.cost_per_sms, 0),
          'price_per_email', COALESCE(c.cost_per_email, 0)
        )
        ORDER BY (c.call_cost + c.sms_cost + c.email_cost) DESC
      ), '[]'::jsonb)
      FROM combined c
      WHERE c.total_calls > 0 OR c.total_segments > 0 OR c.total_emails > 0
    )
  )
  INTO v_result
  FROM totals t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_user_consumption_metrics(date, date, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_consumption_metrics(date, date, uuid) TO service_role;

COMMENT ON FUNCTION get_user_consumption_metrics IS
'Retourne les metriques de consommation pour les utilisateurs.
SECURITE: NE retourne JAMAIS provider_cost, margin, margin_percentage.
Retourne uniquement: volumes, prix unitaires (depuis config), cout client (billed_cost).
Filtre par user_client_permissions + auth.uid().';


-- ============================================================================
-- PARTIE 3: get_admin_billing_summary()
-- Resume facturation pour admin (AVEC marge)
-- SECURITE: Verifie is_admin() en premier
-- ============================================================================

DROP FUNCTION IF EXISTS get_admin_billing_summary(date, date);

CREATE OR REPLACE FUNCTION get_admin_billing_summary(
  p_current_month_start date,
  p_current_month_end date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_prev_month_start date;
  v_prev_month_end date;
BEGIN
  -- SECURITE: Verifier que l'utilisateur est admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin permission required for billing summary'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculer les dates du mois precedent
  v_prev_month_start := (p_current_month_start - INTERVAL '1 month')::date;
  v_prev_month_end := (p_current_month_start - INTERVAL '1 day')::date;

  -- Construire le resultat
  SELECT jsonb_build_object(
    'current_month', jsonb_build_object(
      'period', jsonb_build_object(
        'start_date', p_current_month_start,
        'end_date', p_current_month_end
      ),
      'totals', (
        SELECT jsonb_build_object(
          'total_revenue', ROUND(COALESCE(SUM(total_revenue), 0)::numeric, 2),
          'leasing_revenue', ROUND(COALESCE(SUM(leasing_revenue_daily), 0)::numeric, 2),
          'call_revenue', ROUND(COALESCE(SUM(call_revenue), 0)::numeric, 2),
          'sms_revenue', ROUND(COALESCE(SUM(sms_revenue), 0)::numeric, 2),
          'email_revenue', ROUND(COALESCE(SUM(email_revenue), 0)::numeric, 2),
          'total_provider_cost', ROUND(COALESCE(SUM(total_provider_cost), 0)::numeric, 2),
          'total_margin', ROUND(COALESCE(SUM(total_margin), 0)::numeric, 2),
          'margin_percentage', CASE
            WHEN SUM(total_revenue) > 0
            THEN ROUND((SUM(total_margin) / SUM(total_revenue) * 100)::numeric, 2)
            ELSE 0
          END,
          'call_count', COALESCE(SUM(call_count), 0),
          'sms_count', COALESCE(SUM(sms_count), 0),
          'email_count', COALESCE(SUM(email_count), 0),
          'unique_clients', COUNT(DISTINCT client_id),
          'unique_deployments', COUNT(DISTINCT deployment_id)
        )
        FROM v_financial_metrics_enriched
        WHERE metric_date >= p_current_month_start
          AND metric_date <= p_current_month_end
      ),
      'by_company', (
        SELECT COALESCE(jsonb_agg(company_data ORDER BY company_data->>'total_revenue' DESC), '[]'::jsonb)
        FROM (
          SELECT jsonb_build_object(
            'client_id', client_id,
            'client_name', client_name,
            'total_revenue', ROUND(SUM(total_revenue)::numeric, 2),
            'leasing_revenue', ROUND(SUM(leasing_revenue_daily)::numeric, 2),
            'consumption_revenue', ROUND(SUM(call_revenue + sms_revenue + email_revenue)::numeric, 2),
            'total_provider_cost', ROUND(SUM(total_provider_cost)::numeric, 2),
            'total_margin', ROUND(SUM(total_margin)::numeric, 2),
            'margin_percentage', CASE
              WHEN SUM(total_revenue) > 0
              THEN ROUND((SUM(total_margin) / SUM(total_revenue) * 100)::numeric, 2)
              ELSE 0
            END,
            'agents', (
              SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                  'deployment_id', sub.deployment_id,
                  'deployment_name', ad.name,
                  'agent_type_name', at.name,
                  'total_revenue', ROUND(sub.revenue::numeric, 2),
                  'leasing_revenue', ROUND(sub.leasing::numeric, 2),
                  'call_revenue', ROUND(sub.calls::numeric, 2),
                  'sms_revenue', ROUND(sub.sms::numeric, 2),
                  'email_revenue', ROUND(sub.emails::numeric, 2),
                  'total_margin', ROUND(sub.margin::numeric, 2),
                  'margin_percentage', CASE
                    WHEN sub.revenue > 0
                    THEN ROUND((sub.margin / sub.revenue * 100)::numeric, 2)
                    ELSE 0
                  END
                )
                ORDER BY sub.revenue DESC
              ), '[]'::jsonb)
              FROM (
                SELECT
                  fm2.deployment_id,
                  SUM(fm2.total_revenue) AS revenue,
                  SUM(fm2.leasing_revenue_daily) AS leasing,
                  SUM(fm2.call_revenue) AS calls,
                  SUM(fm2.sms_revenue) AS sms,
                  SUM(fm2.email_revenue) AS emails,
                  SUM(fm2.total_margin) AS margin
                FROM v_financial_metrics_enriched fm2
                WHERE fm2.client_id = fm.client_id
                  AND fm2.metric_date >= p_current_month_start
                  AND fm2.metric_date <= p_current_month_end
                GROUP BY fm2.deployment_id
              ) sub
              JOIN agent_deployments ad ON sub.deployment_id = ad.id
              JOIN agent_types at ON ad.agent_type_id = at.id
            )
          ) AS company_data
          FROM v_financial_metrics_enriched fm
          WHERE fm.metric_date >= p_current_month_start
            AND fm.metric_date <= p_current_month_end
          GROUP BY fm.client_id, fm.client_name
        ) companies
      )
    ),

    'previous_month', jsonb_build_object(
      'period', jsonb_build_object(
        'start_date', v_prev_month_start,
        'end_date', v_prev_month_end
      ),
      'totals', (
        SELECT jsonb_build_object(
          'total_revenue', ROUND(COALESCE(SUM(total_revenue), 0)::numeric, 2),
          'leasing_revenue', ROUND(COALESCE(SUM(leasing_revenue_daily), 0)::numeric, 2),
          'consumption_revenue', ROUND(COALESCE(SUM(call_revenue + sms_revenue + email_revenue), 0)::numeric, 2),
          'total_provider_cost', ROUND(COALESCE(SUM(total_provider_cost), 0)::numeric, 2),
          'total_margin', ROUND(COALESCE(SUM(total_margin), 0)::numeric, 2),
          'margin_percentage', CASE
            WHEN SUM(total_revenue) > 0
            THEN ROUND((SUM(total_margin) / SUM(total_revenue) * 100)::numeric, 2)
            ELSE 0
          END,
          'call_count', COALESCE(SUM(call_count), 0),
          'sms_count', COALESCE(SUM(sms_count), 0),
          'email_count', COALESCE(SUM(email_count), 0)
        )
        FROM v_financial_metrics_enriched
        WHERE metric_date >= v_prev_month_start
          AND metric_date <= v_prev_month_end
      ),
      'by_company', (
        SELECT COALESCE(jsonb_agg(company_data ORDER BY company_data->>'total_revenue' DESC), '[]'::jsonb)
        FROM (
          SELECT jsonb_build_object(
            'client_id', client_id,
            'client_name', client_name,
            'total_revenue', ROUND(SUM(total_revenue)::numeric, 2),
            'leasing_revenue', ROUND(SUM(leasing_revenue_daily)::numeric, 2),
            'consumption_revenue', ROUND(SUM(call_revenue + sms_revenue + email_revenue)::numeric, 2),
            'total_margin', ROUND(SUM(total_margin)::numeric, 2),
            'margin_percentage', CASE
              WHEN SUM(total_revenue) > 0
              THEN ROUND((SUM(total_margin) / SUM(total_revenue) * 100)::numeric, 2)
              ELSE 0
            END
          ) AS company_data
          FROM v_financial_metrics_enriched fm
          WHERE fm.metric_date >= v_prev_month_start
            AND fm.metric_date <= v_prev_month_end
          GROUP BY fm.client_id, fm.client_name
        ) companies
      )
    )
  )
  INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_billing_summary(date, date) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_billing_summary(date, date) TO service_role;

COMMENT ON FUNCTION get_admin_billing_summary IS
'Retourne le resume de facturation pour les administrateurs.
SECURITE: Verifie is_admin() en premier - echoue si non-admin.
Inclut: leasing, consommation, marges, couts fournisseur.
Fournit mois en cours + mois precedent pour comparaison.';


-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verification: Lister les fonctions creees
-- SELECT routine_name, routine_type
-- FROM information_schema.routines
-- WHERE routine_schema = 'public'
-- AND routine_name IN ('get_company_agent_hierarchy', 'get_user_consumption_metrics', 'get_admin_billing_summary');

-- Test: get_company_agent_hierarchy()
-- SELECT get_company_agent_hierarchy();

-- Test: get_user_consumption_metrics()
-- SELECT get_user_consumption_metrics('2025-12-01'::date, '2025-12-15'::date);

-- Test: get_admin_billing_summary() (admin only)
-- SELECT get_admin_billing_summary('2025-12-01'::date, '2025-12-31'::date);
