-- Address Supabase security advisors (lints 0010, 0011, 0028, 0029).
-- Applied via MCP apply_migration on 2026-05-06 — file checked in for repo parity.

-- Lint 0010: v_healing_calls was implicit SECURITY DEFINER. Make it caller-scoped.
ALTER VIEW public.v_healing_calls SET (security_invoker = true);

-- Lint 0011: pin search_path on SECURITY INVOKER functions to block hijack via search_path.
ALTER FUNCTION public.get_agent_cards_data(date, date, text)                       SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.get_outcome_distribution(date, date, uuid, text)             SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.get_calls_page(date, date, uuid, text, text, text, text, integer, integer)
                                                                                     SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.get_dashboard_kpis(date, date, uuid, text)                   SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.calculate_call_billing()                                      SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.update_updated_at()                                           SET search_path = 'public', 'pg_temp';
ALTER FUNCTION public.get_call_volume_by_day(date, date, uuid, text)               SET search_path = 'public', 'pg_temp';

-- Lints 0028/0029: worker + ingest SECURITY DEFINER fns must be service_role only.
REVOKE EXECUTE ON FUNCTION public.check_recent_call_to_phone(text, uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_pending_callbacks(integer)                 FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_pending_retries(integer)                   FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.sablia_board_ingest_lookup(text, text)           FROM PUBLIC, anon, authenticated;

-- Dashboard RPC: revoke anon (was unintended), keep authenticated.
REVOKE EXECUTE ON FUNCTION public.get_consumption_metrics(date, date, boolean) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_consumption_metrics(date, date, boolean) TO authenticated;

COMMENT ON FUNCTION public.get_consumption_metrics(date, date, boolean) IS
  'Dashboard RPC. SECURITY DEFINER intentional: reads org_id/is_admin from auth.jwt() app_metadata to scope per-deployment metrics across orgs (admin) or restrict to user org_ids (non-admin). Linter 0029 expected — do not switch to SECURITY INVOKER (RLS on calls/sms/emails/agent_deployments would break the admin cross-org view).';
