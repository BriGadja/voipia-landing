-- Migration: Create scheduled_callbacks table
-- Date: 2025-12-23
-- Description: Table for storing scheduled callback requests from n8n workflows
-- Part of: Callback System Feature

-- ============================================================================
-- TABLE: scheduled_callbacks
-- File d'attente des rappels programmés par n8n
-- ============================================================================

CREATE TABLE IF NOT EXISTS scheduled_callbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Liens vers les tables existantes
  original_call_id UUID NOT NULL REFERENCES agent_calls(id) ON DELETE CASCADE,
  deployment_id UUID NOT NULL REFERENCES agent_deployments(id) ON DELETE CASCADE,

  -- Informations contact (dénormalisées pour efficacité n8n)
  phone_number TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  email TEXT,

  -- Planification
  scheduled_at TIMESTAMPTZ NOT NULL,

  -- Suivi des tentatives
  attempt_number INTEGER NOT NULL DEFAULT 1,
  max_attempts INTEGER NOT NULL DEFAULT 3,

  -- Nom de la règle n8n qui a créé ce rappel
  rule_name TEXT NOT NULL,

  -- Statut du rappel
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',           -- En attente d'exécution
    'in_progress',       -- En cours de traitement par n8n
    'executed',          -- Rappel effectué
    'cancelled',         -- Annulé manuellement
    'max_attempts',      -- Nombre max de tentatives atteint
    'expired',           -- Fenêtre de temps dépassée
    'contact_converted'  -- Contact a pris RDV, plus de rappels nécessaires
  )),

  -- Suivi d'exécution
  executed_at TIMESTAMPTZ,
  result_call_id UUID REFERENCES agent_calls(id),

  -- Métadonnées flexibles
  metadata JSONB DEFAULT '{}',
  cancellation_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index principal pour les requêtes n8n (rappels à exécuter)
CREATE INDEX idx_scheduled_callbacks_pending
  ON scheduled_callbacks(scheduled_at, deployment_id)
  WHERE status = 'pending';

-- Index pour retrouver les rappels d'un appel original
CREATE INDEX idx_scheduled_callbacks_original_call
  ON scheduled_callbacks(original_call_id);

-- Index pour éviter les doublons par numéro de téléphone
CREATE INDEX idx_scheduled_callbacks_phone_deployment
  ON scheduled_callbacks(phone_number, deployment_id, status);

-- Index pour le dashboard (filtrage par statut)
CREATE INDEX idx_scheduled_callbacks_status
  ON scheduled_callbacks(status, created_at DESC);

-- Index pour le dashboard (filtrage par déploiement)
CREATE INDEX idx_scheduled_callbacks_deployment
  ON scheduled_callbacks(deployment_id, created_at DESC);

-- ============================================================================
-- TRIGGER: Mise à jour automatique de updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_scheduled_callbacks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_scheduled_callbacks_updated_at
  BEFORE UPDATE ON scheduled_callbacks
  FOR EACH ROW
  EXECUTE FUNCTION update_scheduled_callbacks_updated_at();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE scheduled_callbacks IS 'File d''attente des rappels programmés par les workflows n8n';
COMMENT ON COLUMN scheduled_callbacks.original_call_id IS 'Référence à l''appel qui a déclenché ce rappel';
COMMENT ON COLUMN scheduled_callbacks.rule_name IS 'Nom de la règle n8n qui a créé ce rappel (ex: voicemail_retry_2h)';
COMMENT ON COLUMN scheduled_callbacks.attempt_number IS 'Numéro de tentative actuel (1, 2, 3...)';
COMMENT ON COLUMN scheduled_callbacks.max_attempts IS 'Nombre maximum de tentatives configuré dans le workflow n8n';
COMMENT ON COLUMN scheduled_callbacks.result_call_id IS 'Référence à l''appel résultant du rappel (si exécuté)';

-- ============================================================================
-- Verification query (commented)
-- SELECT COUNT(*) FROM scheduled_callbacks;
-- ============================================================================
