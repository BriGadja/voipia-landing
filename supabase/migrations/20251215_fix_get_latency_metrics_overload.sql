-- Fix: Remove duplicate RPC functions causing PGRST203 overload errors
-- Date: 2025-12-15
--
-- Problem: Multiple versions of functions exist with similar signatures:
--   - get_latency_metrics: date vs timestamp with time zone
--   - get_chart_data: uuid vs uuid[] for p_client_id
--   - get_kpi_metrics: uuid vs uuid[] for p_client_id
-- PostgREST cannot disambiguate between them when called via API.
--
-- Solution: Remove the duplicate versions, keep single-parameter versions.

-- 1. Remove timestamp version of get_latency_metrics
DROP FUNCTION IF EXISTS get_latency_metrics(timestamp with time zone, timestamp with time zone, uuid, uuid, text);

-- 2. Remove uuid[] array versions of get_chart_data and get_kpi_metrics
DROP FUNCTION IF EXISTS get_chart_data(date, date, uuid[], uuid, text);
DROP FUNCTION IF EXISTS get_kpi_metrics(date, date, uuid[], uuid, text);

-- Verification (uncomment to test):
-- SELECT p.proname, pg_get_function_arguments(p.oid)
-- FROM pg_proc p
-- JOIN pg_namespace n ON p.pronamespace = n.oid
-- WHERE n.nspname = 'public'
--   AND p.proname IN ('get_latency_metrics', 'get_chart_data', 'get_kpi_metrics');
