-- ============================================
-- SCHEMA BACKUP - AVANT NETTOYAGE
-- Date: 2025-01-13
-- Environment: Staging
-- Description: Backup du schéma complet avant modifications
-- ============================================

-- ============================================
-- TABLES (8 tables)
-- ============================================

-- Base tables in public schema:
-- 1. agent_arthur_prospect_sequences
-- 2. agent_arthur_prospects
-- 3. agent_calls
-- 4. agent_deployments
-- 5. agent_types
-- 6. clients
-- 7. profiles
-- 8. user_client_permissions

-- ============================================
-- VIEWS (16 views)
-- ============================================

-- Views in public schema:
-- 1. v_agent_calls_enriched (SECURITY DEFINER - TO FIX)
-- 2. v_arthur_calls_enriched (SECURITY DEFINER - TO FIX)
-- 3. v_arthur_next_call_exoticdesign (SECURITY DEFINER - TO FIX)
-- 4. v_arthur_next_call_norloc (SECURITY DEFINER - TO FIX)
-- 5. v_arthur_next_call_stefanodesign (SECURITY DEFINER - TO FIX)
-- 6. v_arthur_next_calls (SECURITY DEFINER - TO FIX)
-- 7. v_arthur_next_calls_global (SECURITY DEFINER - TO FIX)
-- 8. v_global_agent_type_performance (SECURITY DEFINER - TO FIX)
-- 9. v_global_call_volume_by_day (SECURITY DEFINER - TO FIX)
-- 10. v_global_kpis (SECURITY DEFINER - TO FIX)
-- 11. v_global_outcome_distribution (SECURITY DEFINER - TO FIX)
-- 12. v_global_top_clients (SECURITY DEFINER - TO FIX)
-- 13. v_louis_agent_performance (SECURITY DEFINER - TO FIX)
-- 14. v_prospects_attempts_exceeded (SECURITY DEFINER - TO FIX)
-- 15. v_user_accessible_agents (SECURITY DEFINER - TO FIX)
-- 16. v_user_accessible_clients (SECURITY DEFINER - TO FIX)

-- ============================================
-- RLS POLICIES (12 policies actuelles)
-- ============================================

-- agent_calls (2 policies)
CREATE POLICY "admin_see_all_calls" ON public.agent_calls
  FOR SELECT USING ((auth.jwt() ->> 'role'::text) = 'admin'::text);

CREATE POLICY "client_see_own_calls" ON public.agent_calls
  FOR SELECT USING (
    deployment_id IN (
      SELECT agent_deployments.id
      FROM agent_deployments
      WHERE (agent_deployments.client_id = ((auth.jwt() ->> 'client_id'::text))::uuid)
    )
  );

-- agent_deployments (3 policies)
CREATE POLICY "admin_manage_all_deployments" ON public.agent_deployments
  FOR ALL USING ((auth.jwt() ->> 'role'::text) = 'admin'::text);

CREATE POLICY "admin_see_all_deployments" ON public.agent_deployments
  FOR SELECT USING ((auth.jwt() ->> 'role'::text) = 'admin'::text);

CREATE POLICY "client_see_own_deployments" ON public.agent_deployments
  FOR SELECT USING (client_id = ((auth.jwt() ->> 'client_id'::text))::uuid);

-- agent_types (2 policies)
CREATE POLICY "admin_can_manage_agent_types" ON public.agent_types
  FOR ALL USING ((auth.jwt() ->> 'role'::text) = 'admin'::text);

CREATE POLICY "anyone_can_read_agent_types" ON public.agent_types
  FOR SELECT USING (true);

-- clients (1 policy)
CREATE POLICY "users_view_their_clients" ON public.clients
  FOR SELECT TO authenticated USING (
    id IN (
      SELECT user_client_permissions.client_id
      FROM user_client_permissions
      WHERE (user_client_permissions.user_id = auth.uid())
    )
  );

-- profiles (3 policies)
CREATE POLICY "admins_view_all_profiles" ON public.profiles
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1
      FROM profiles profiles_1
      WHERE ((profiles_1.id = auth.uid()) AND (profiles_1.role = 'admin'::text))
    )
  );

CREATE POLICY "users_update_own_profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "users_view_own_profile" ON public.profiles
  FOR SELECT TO authenticated USING (id = auth.uid());

-- user_client_permissions (1 policy)
CREATE POLICY "users_view_own_permissions" ON public.user_client_permissions
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- agent_arthur_prospects (0 policies - TO FIX: RLS enabled but no policies)
-- agent_arthur_prospect_sequences (0 policies - TO FIX: RLS enabled but no policies)

-- ============================================
-- INDEXES (58 indexes totaux)
-- ============================================

-- agent_arthur_prospect_sequences (8 indexes, dont 3 non utilisés)
CREATE UNIQUE INDEX agent_arthur_prospect_sequences_pkey ON public.agent_arthur_prospect_sequences USING btree (id);
CREATE INDEX idx_arthur_sequences_next_action ON public.agent_arthur_prospect_sequences USING btree (next_action_at, status) WHERE (status = ANY (ARRAY['active'::text, 'callback'::text]));
CREATE UNIQUE INDEX idx_prospect_sequences_unique ON public.agent_arthur_prospect_sequences USING btree (prospect_id, deployment_id, sequence_number);
CREATE INDEX idx_sequences_deployment_status ON public.agent_arthur_prospect_sequences USING btree (deployment_id, status); -- NON UTILISÉ
CREATE INDEX idx_sequences_next_action ON public.agent_arthur_prospect_sequences USING btree (next_action_at) WHERE (status = 'active'::text); -- NON UTILISÉ
CREATE INDEX idx_sequences_prospect ON public.agent_arthur_prospect_sequences USING btree (prospect_id); -- NON UTILISÉ
CREATE INDEX idx_sequences_started_at ON public.agent_arthur_prospect_sequences USING btree (started_at);
CREATE UNIQUE INDEX unique_active_sequence_per_prospect ON public.agent_arthur_prospect_sequences USING btree (prospect_id, sequence_number);

-- agent_arthur_prospects (10 indexes, dont 7 non utilisés)
CREATE UNIQUE INDEX agent_arthur_prospects_pkey ON public.agent_arthur_prospects USING btree (id);
CREATE INDEX idx_prospects_client_slug ON public.agent_arthur_prospects USING btree (client_slug); -- NON UTILISÉ
CREATE INDEX idx_prospects_created_at ON public.agent_arthur_prospects USING btree (created_at); -- NON UTILISÉ
CREATE UNIQUE INDEX idx_prospects_deployment_external_deal ON public.agent_arthur_prospects USING btree (deployment_id, external_deal_id);
CREATE INDEX idx_prospects_deployment_status ON public.agent_arthur_prospects USING btree (deployment_id, status); -- NON UTILISÉ
CREATE INDEX idx_prospects_external_deal_id ON public.agent_arthur_prospects USING btree (external_deal_id); -- NON UTILISÉ
CREATE INDEX idx_prospects_external_deal_user ON public.agent_arthur_prospects USING btree (external_deal_id, external_user_id); -- NON UTILISÉ
CREATE INDEX idx_prospects_external_user_id ON public.agent_arthur_prospects USING btree (external_user_id) WHERE (external_user_id IS NOT NULL); -- NON UTILISÉ
CREATE INDEX idx_prospects_phone ON public.agent_arthur_prospects USING btree (phone_number); -- NON UTILISÉ
CREATE UNIQUE INDEX unique_external_deal_per_deployment ON public.agent_arthur_prospects USING btree (deployment_id, external_deal_id, external_user_id, external_source) NULLS NOT DISTINCT;

-- agent_calls (20 indexes, dont 27 présents initialement)
CREATE UNIQUE INDEX agent_calls_conversation_id_key ON public.agent_calls USING btree (conversation_id);
CREATE UNIQUE INDEX agent_calls_pkey ON public.agent_calls USING btree (id);
CREATE INDEX idx_agent_calls_deployment_started_at ON public.agent_calls USING btree (deployment_id, started_at DESC);
CREATE INDEX idx_agent_calls_metadata_appointment ON public.agent_calls USING btree (((metadata ->> 'appointment_scheduled_at'::text))) WHERE ((metadata ->> 'appointment_scheduled_at'::text) IS NOT NULL);
CREATE INDEX idx_agent_calls_outcome ON public.agent_calls USING btree (outcome);
CREATE INDEX idx_agent_calls_prospect ON public.agent_calls USING btree (prospect_id);
CREATE INDEX idx_agent_calls_sequence ON public.agent_calls USING btree (sequence_id);
CREATE INDEX idx_agent_calls_started_at_deployment ON public.agent_calls USING btree (started_at DESC, deployment_id);
CREATE INDEX idx_calls_call_sid ON public.agent_calls USING btree (call_sid);
CREATE INDEX idx_calls_classification ON public.agent_calls USING btree (call_classification) WHERE (call_classification IS NOT NULL);
CREATE INDEX idx_calls_conversation_id ON public.agent_calls USING btree (conversation_id);
CREATE INDEX idx_calls_created_at ON public.agent_calls USING btree (created_at DESC);
CREATE INDEX idx_calls_deployment ON public.agent_calls USING btree (deployment_id, started_at DESC); -- DOUBLON avec idx_agent_calls_deployment_started_at
CREATE INDEX idx_calls_deployment_emotion ON public.agent_calls USING btree (deployment_id, emotion) WHERE (emotion IS NOT NULL);
CREATE INDEX idx_calls_deployment_outcome_date ON public.agent_calls USING btree (deployment_id, outcome, started_at DESC);
CREATE INDEX idx_calls_direction ON public.agent_calls USING btree (direction);
CREATE INDEX idx_calls_llm_model ON public.agent_calls USING btree (llm_model) WHERE (llm_model IS NOT NULL);
CREATE INDEX idx_calls_metadata ON public.agent_calls USING gin (metadata);
CREATE INDEX idx_calls_quality_score ON public.agent_calls USING btree (call_quality_score) WHERE (call_quality_score IS NOT NULL);
CREATE INDEX idx_calls_sentiment ON public.agent_calls USING btree (sentiment_analysis) WHERE (sentiment_analysis IS NOT NULL);

-- agent_deployments (10 indexes, dont 4 non utilisés)
CREATE UNIQUE INDEX agent_deployments_pkey ON public.agent_deployments USING btree (id);
CREATE INDEX idx_agent_deployments_client_type ON public.agent_deployments USING btree (client_id, agent_type_id) WHERE (status = 'active'::text); -- NON UTILISÉ
CREATE INDEX idx_deployments_agent_type ON public.agent_deployments USING btree (agent_type_id);
CREATE INDEX idx_deployments_client ON public.agent_deployments USING btree (client_id); -- NON UTILISÉ
CREATE INDEX idx_deployments_client_agent ON public.agent_deployments USING btree (client_id, agent_type_id); -- NON UTILISÉ
CREATE INDEX idx_deployments_slug ON public.agent_deployments USING btree (slug);
CREATE INDEX idx_deployments_status ON public.agent_deployments USING btree (status) WHERE (status = 'active'::text); -- NON UTILISÉ
CREATE UNIQUE INDEX unique_deployment_per_client_agent ON public.agent_deployments USING btree (client_id, agent_type_id);
CREATE UNIQUE INDEX unique_slug ON public.agent_deployments USING btree (slug);

-- agent_types (4 indexes, dont 1 non utilisé)
CREATE UNIQUE INDEX agent_types_name_key ON public.agent_types USING btree (name);
CREATE UNIQUE INDEX agent_types_pkey ON public.agent_types USING btree (id);
CREATE INDEX idx_agent_types_name ON public.agent_types USING btree (name);
CREATE INDEX idx_agent_types_status ON public.agent_types USING btree (status) WHERE (status = 'active'::text); -- NON UTILISÉ

-- clients (2 indexes, dont 1 non utilisé)
CREATE UNIQUE INDEX clients_pkey ON public.clients USING btree (id);
CREATE INDEX idx_clients_name ON public.clients USING btree (name); -- NON UTILISÉ

-- profiles (3 indexes, dont 2 non utilisés)
CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);
CREATE INDEX idx_profiles_email ON public.profiles USING btree (email); -- NON UTILISÉ
CREATE INDEX idx_profiles_role ON public.profiles USING btree (role); -- NON UTILISÉ

-- user_client_permissions (3 indexes)
CREATE UNIQUE INDEX user_client_permissions_pkey ON public.user_client_permissions USING btree (user_id, client_id);
CREATE INDEX idx_user_client_permissions_client ON public.user_client_permissions USING btree (client_id);
CREATE INDEX idx_user_client_permissions_user ON public.user_client_permissions USING btree (user_id);

-- v_agent_kpis (3 indexes, dont 2 non utilisés - materialized view)
CREATE INDEX idx_agent_kpis_agent_type ON public.v_agent_kpis USING btree (agent_type_id); -- NON UTILISÉ
CREATE INDEX idx_agent_kpis_client ON public.v_agent_kpis USING btree (client_id); -- NON UTILISÉ
CREATE UNIQUE INDEX idx_agent_kpis_deployment ON public.v_agent_kpis USING btree (deployment_id);

-- ============================================
-- RÉSUMÉ DES PROBLÈMES
-- ============================================

-- Total indexes: 58
-- Index uniques/PK: 11
-- Index standards: 47
-- Index non utilisés: 46
-- Index dupliqués: 1 (idx_calls_deployment)

-- Total policies RLS: 12
-- Policies avec auth.uid() non optimisé: 11
-- Tables RLS sans policies: 2 (agent_arthur_prospects, agent_arthur_prospect_sequences)

-- Total vues: 16
-- Vues avec SECURITY DEFINER: 16 (tous à convertir en SECURITY INVOKER)

-- ============================================
-- FIN DU BACKUP
-- ============================================
