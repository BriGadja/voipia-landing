# USER TODO - Configuration Supabase pour Dashboard Analytics

Ce document liste **toutes les tâches que vous devez effectuer dans Supabase** avant que je puisse continuer le développement du dashboard. Je ne peux pas effectuer ces modifications de manière sûre car elles touchent directement à la structure de votre base de données en production.

---

## 📋 Vue d'ensemble

**Pourquoi ces tâches manuelles ?**
- Modifications de schéma database (création tables, colonnes, indexes)
- Configuration de sécurité critique (RLS policies)
- Optimisations performance (BRIN indexes, materialized views)
- Risque de perte de données si mal exécutées

**Mon rôle (Claude Code)** :
- ✅ Générer tout le code SQL nécessaire (voir ci-dessous)
- ✅ Créer les composants React/Next.js
- ✅ Configurer TanStack Query et routing
- ✅ Implémenter les visualisations et filtres

**Votre rôle** :
- ⚠️ Exécuter les scripts SQL dans Supabase
- ⚠️ Vérifier que tout fonctionne
- ⚠️ Me confirmer quand c'est fait

---

## 🎯 Checklist des Tâches

### Phase 1 : Préparation (5 min)

- [ ] **Backup de la base de données**
  - Aller dans Supabase Dashboard → Database → Backups
  - Créer un backup manuel avant toute modification
  - Télécharger un export SQL complet (sécurité)

- [ ] **Ouvrir SQL Editor**
  - Aller dans Supabase Dashboard → SQL Editor
  - Créer une nouvelle query nommée "Dashboard Setup"

---

### Phase 2 : Création des Tables (10 min)

#### ✅ Tâche 1 : Créer la table `agents`

**Objectif** : Gérer les agents vocaux individuels par client

**SQL à exécuter** :
```sql
-- Table agents
CREATE TABLE IF NOT EXISTS agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('inbound', 'outbound')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_agents_client_id ON agents(client_id);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status) WHERE status = 'active';

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_agents_updated_at
  BEFORE UPDATE ON agents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Policy : Users voient les agents de leurs clients
CREATE POLICY "users_view_their_agents"
  ON agents FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT client_id FROM user_client_permissions
      WHERE user_id = auth.uid()
    )
  );

COMMENT ON TABLE agents IS 'Agents vocaux IA appartenant aux clients';
```

**Vérification** :
```sql
-- Doit retourner la structure de la table agents
SELECT * FROM agents LIMIT 1;
```

- [ ] **Confirmé : Table `agents` créée avec succès**

---

#### ✅ Tâche 2 : Créer la table `user_client_permissions`

**Objectif** : Gérer qui peut voir quels clients (permissions granulaires)

**SQL à exécuter** :
```sql
-- Table permissions
CREATE TABLE IF NOT EXISTS user_client_permissions (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  permission_level TEXT NOT NULL DEFAULT 'read' CHECK (permission_level IN ('read', 'write', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, client_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_user_client_permissions_user ON user_client_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_client_permissions_client ON user_client_permissions(client_id);

-- Enable RLS
ALTER TABLE user_client_permissions ENABLE ROW LEVEL SECURITY;

-- Policy : Users voient leurs propres permissions
CREATE POLICY "users_view_own_permissions"
  ON user_client_permissions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

COMMENT ON TABLE user_client_permissions IS 'Permissions granulaires user-client';
```

**Vérification** :
```sql
-- Doit retourner la structure de la table
SELECT * FROM user_client_permissions LIMIT 1;
```

- [ ] **Confirmé : Table `user_client_permissions` créée avec succès**

---

### Phase 3 : Modification de la Table `calls` (5 min)

#### ✅ Tâche 3 : Ajouter la colonne `agent_id`

**Objectif** : Lier chaque appel à un agent spécifique

**SQL à exécuter** :
```sql
-- Ajouter colonne agent_id si elle n'existe pas
ALTER TABLE calls
ADD COLUMN IF NOT EXISTS agent_id UUID REFERENCES agents(id) ON DELETE SET NULL;

-- Ajouter index pour performance
CREATE INDEX IF NOT EXISTS idx_calls_agent_id ON calls(agent_id);

COMMENT ON COLUMN calls.agent_id IS 'Agent vocal ayant passé cet appel';
```

**Vérification** :
```sql
-- Doit afficher la colonne agent_id
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'calls' AND column_name = 'agent_id';
```

- [ ] **Confirmé : Colonne `agent_id` ajoutée à `calls`**

---

### Phase 4 : Indexes de Performance (10 min)

#### ✅ Tâche 4 : Créer les indexes critiques

**Objectif** : Optimiser les requêtes time-series et filtres fréquents

**SQL à exécuter** :
```sql
-- BRIN index pour started_at (99% plus léger que B-tree pour time-series)
CREATE INDEX IF NOT EXISTS idx_calls_started_at_brin
ON calls USING BRIN (started_at)
WITH (pages_per_range = 128);

-- Composite indexes pour filtres fréquents
CREATE INDEX IF NOT EXISTS idx_calls_client_started
ON calls (client_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_calls_agent_started
ON calls (agent_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_calls_client_agent_started
ON calls (client_id, agent_id, started_at DESC);

-- Index pour filtrage par call_outcome
CREATE INDEX IF NOT EXISTS idx_calls_outcome
ON calls (call_outcome) WHERE call_outcome IS NOT NULL;

-- Index pour filtrage par émotion
CREATE INDEX IF NOT EXISTS idx_calls_emotion
ON calls (emotion) WHERE emotion IS NOT NULL;

-- Index pour les RDV
CREATE INDEX IF NOT EXISTS idx_calls_appointments
ON calls (appointment_scheduled_at) WHERE appointment_scheduled_at IS NOT NULL;
```

**Vérification** :
```sql
-- Doit afficher tous les indexes créés
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'calls'
ORDER BY indexname;
```

- [ ] **Confirmé : Tous les indexes créés avec succès**

---

### Phase 5 : Materialized View (15 min)

#### ✅ Tâche 5 : Créer la vue matérialisée pour métriques quotidiennes

**Objectif** : Pré-calculer les agrégations pour améliorer les performances

**SQL à exécuter** :
```sql
-- Vue matérialisée pour métriques quotidiennes
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_call_metrics AS
SELECT
  client_id,
  agent_id,
  DATE(started_at) as metric_date,

  -- Métriques prioritaires
  COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL) as appointments_scheduled,
  COUNT(*) FILTER (WHERE call_outcome = 'voicemail') as voicemail_count,
  COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')) as answered_count,

  -- Durée et coût
  ROUND(AVG(duration_seconds)) as avg_duration_seconds,
  ROUND(SUM(cost)::NUMERIC, 2) as total_cost,
  ROUND(AVG(cost)::NUMERIC, 2) as avg_cost,

  -- Distribution émotions
  COUNT(*) FILTER (WHERE emotion = 'positive') as emotion_positive,
  COUNT(*) FILTER (WHERE emotion = 'neutral') as emotion_neutral,
  COUNT(*) FILTER (WHERE emotion = 'negative') as emotion_negative,

  -- Total
  COUNT(*) as total_calls

FROM calls
WHERE started_at >= CURRENT_DATE - INTERVAL '365 days'
GROUP BY client_id, agent_id, DATE(started_at);

-- Index sur la vue matérialisée
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_metrics_unique
ON daily_call_metrics (client_id, agent_id, metric_date);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_client_date
ON daily_call_metrics (client_id, metric_date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_agent_date
ON daily_call_metrics (agent_id, metric_date DESC);

COMMENT ON MATERIALIZED VIEW daily_call_metrics IS 'Agrégations quotidiennes des métriques d appels (refresh horaire recommandé)';
```

**Premier refresh** :
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_call_metrics;
```

**Vérification** :
```sql
-- Doit afficher des données agrégées
SELECT * FROM daily_call_metrics LIMIT 10;

-- Vérifier le nombre de rows
SELECT COUNT(*) FROM daily_call_metrics;
```

- [ ] **Confirmé : Materialized view créée et populée**

---

#### ✅ Tâche 5b : Configurer le refresh automatique (OPTIONNEL)

**Option A - Via pg_cron (si disponible)** :
```sql
-- Vérifier si pg_cron est disponible
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- Si disponible, créer un job pour refresh toutes les heures
SELECT cron.schedule(
  'refresh-daily-metrics',
  '0 * * * *', -- Toutes les heures
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY daily_call_metrics$$
);
```

**Option B - Refresh manuel régulier** :
- Créer un reminder pour exécuter le refresh 1x/jour :
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_call_metrics;
```

**Option C - Via l'application Next.js** :
- Je peux créer un API route qui refresh la view (à appeler via cron externe)

- [ ] **Confirmé : Refresh automatique configuré** (ou décision prise)

---

### Phase 6 : Fonctions SQL pour Queries Complexes (10 min)

#### ✅ Tâche 6 : Créer la fonction `get_kpi_metrics`

**Objectif** : Fonction optimisée pour calculer les KPIs

**SQL à exécuter** :
```sql
-- Fonction pour obtenir les KPIs avec période de comparaison
CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_agent_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
  prev_start_date TIMESTAMPTZ;
  prev_end_date TIMESTAMPTZ;
BEGIN
  -- Calculer période précédente de même durée
  prev_end_date := p_start_date - INTERVAL '1 second';
  prev_start_date := prev_end_date - (p_end_date - p_start_date);

  -- Construire le JSON de résultats
  SELECT json_build_object(
    'current_period', (
      SELECT json_build_object(
        'appointments_scheduled', COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL),
        'answer_rate', COALESCE(ROUND((COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested'))::NUMERIC / NULLIF(COUNT(*), 0) * 100), 2), 0),
        'avg_duration', COALESCE(ROUND(AVG(duration_seconds)), 0),
        'avg_cost', COALESCE(ROUND(AVG(cost)::NUMERIC, 2), 0),
        'conversion_rate', COALESCE(ROUND((COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL)::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')), 0) * 100), 2), 0),
        'total_cost', COALESCE(ROUND(SUM(cost)::NUMERIC, 2), 0),
        'total_calls', COUNT(*),
        'cpa', COALESCE(ROUND((SUM(cost) / NULLIF(COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL), 0))::NUMERIC, 2), 0)
      )
      FROM calls
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
    ),
    'previous_period', (
      SELECT json_build_object(
        'appointments_scheduled', COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL),
        'answer_rate', COALESCE(ROUND((COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested'))::NUMERIC / NULLIF(COUNT(*), 0) * 100), 2), 0),
        'avg_duration', COALESCE(ROUND(AVG(duration_seconds)), 0),
        'avg_cost', COALESCE(ROUND(AVG(cost)::NUMERIC, 2), 0),
        'conversion_rate', COALESCE(ROUND((COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL)::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')), 0) * 100), 2), 0),
        'total_calls', COUNT(*)
      )
      FROM calls
      WHERE started_at >= prev_start_date
        AND started_at <= prev_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
    )
  )
  INTO result;

  RETURN result;
END;
$$;

COMMENT ON FUNCTION get_kpi_metrics IS 'Calcule les KPIs pour une période avec comparaison période précédente';
```

**Vérification** :
```sql
-- Test de la fonction (adapter les dates)
SELECT get_kpi_metrics(
  '2024-01-01'::TIMESTAMPTZ,
  NOW()::TIMESTAMPTZ,
  NULL, -- Tous les clients
  NULL  -- Tous les agents
);
```

- [ ] **Confirmé : Fonction `get_kpi_metrics` créée et testée**

---

#### ✅ Tâche 7 : Créer la fonction `get_chart_data`

**Objectif** : Fonction pour obtenir les données de charts

**SQL à exécuter** :
```sql
-- Fonction pour obtenir les données des charts
CREATE OR REPLACE FUNCTION get_chart_data(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_agent_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'call_volume_by_day', (
      SELECT json_agg(
        json_build_object(
          'date', TO_CHAR(DATE(started_at), 'YYYY-MM-DD'),
          'total_calls', COUNT(*),
          'answered_calls', COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')),
          'appointments', COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL)
        ) ORDER BY DATE(started_at)
      )
      FROM calls
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
      GROUP BY DATE(started_at)
    ),
    'emotion_distribution', (
      SELECT json_agg(
        json_build_object(
          'emotion', COALESCE(emotion, 'unknown'),
          'count', COUNT(*)
        )
      )
      FROM calls
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
      GROUP BY emotion
    ),
    'outcome_distribution', (
      SELECT json_agg(
        json_build_object(
          'outcome', call_outcome::TEXT,
          'count', COUNT(*)
        ) ORDER BY COUNT(*) DESC
      )
      FROM calls
      WHERE started_at >= p_start_date
        AND started_at <= p_end_date
        AND (p_client_id IS NULL OR client_id = p_client_id)
        AND (p_agent_id IS NULL OR agent_id = p_agent_id)
        AND call_outcome IS NOT NULL
      GROUP BY call_outcome
    ),
    'voicemail_by_agent', (
      SELECT json_agg(
        json_build_object(
          'agent', COALESCE(a.name, 'Unknown'),
          'rate', ROUND((COUNT(*) FILTER (WHERE c.call_outcome = 'voicemail')::NUMERIC / NULLIF(COUNT(*), 0) * 100), 2)
        ) ORDER BY ROUND((COUNT(*) FILTER (WHERE c.call_outcome = 'voicemail')::NUMERIC / NULLIF(COUNT(*), 0) * 100), 2) DESC
      )
      FROM calls c
      LEFT JOIN agents a ON c.agent_id = a.id
      WHERE c.started_at >= p_start_date
        AND c.started_at <= p_end_date
        AND (p_client_id IS NULL OR c.client_id = p_client_id)
        AND (p_agent_id IS NULL OR c.agent_id = p_agent_id)
      GROUP BY a.name
    )
  )
  INTO result;

  RETURN result;
END;
$$;

COMMENT ON FUNCTION get_chart_data IS 'Retourne les données pour tous les charts du dashboard';
```

**Vérification** :
```sql
-- Test de la fonction
SELECT get_chart_data(
  '2024-01-01'::TIMESTAMPTZ,
  NOW()::TIMESTAMPTZ,
  NULL,
  NULL
);
```

- [ ] **Confirmé : Fonction `get_chart_data` créée et testée**

---

### Phase 7 : RLS Policies (15 min)

#### ✅ Tâche 8 : Configurer les RLS policies sur `calls`

**Objectif** : Sécuriser l'accès aux données (isolation client)

**SQL à exécuter** :
```sql
-- S'assurer que RLS est activé
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies si elles existent
DROP POLICY IF EXISTS "users_view_their_calls" ON calls;

-- Policy : Users voient les appels de leurs clients assignés
CREATE POLICY "users_view_their_calls"
  ON calls FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT client_id
      FROM user_client_permissions
      WHERE user_id = auth.uid()
    )
  );

-- Policy pour insertion (si nécessaire dans le futur)
CREATE POLICY "users_insert_to_their_clients"
  ON calls FOR INSERT
  TO authenticated
  WITH CHECK (
    client_id IN (
      SELECT client_id
      FROM user_client_permissions
      WHERE user_id = auth.uid()
      AND permission_level IN ('write', 'admin')
    )
  );
```

**Vérification** :
```sql
-- Afficher toutes les policies sur calls
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'calls';
```

- [ ] **Confirmé : RLS policies configurées sur `calls`**

---

#### ✅ Tâche 9 : Configurer les RLS policies sur `clients`

**SQL à exécuter** :
```sql
-- S'assurer que RLS est activé
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policy : Users voient leurs clients assignés
DROP POLICY IF EXISTS "users_view_their_clients" ON clients;
CREATE POLICY "users_view_their_clients"
  ON clients FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT client_id
      FROM user_client_permissions
      WHERE user_id = auth.uid()
    )
  );
```

- [ ] **Confirmé : RLS policies configurées sur `clients`**

---

### Phase 8 : Données de Test (OPTIONNEL - 10 min)

#### ✅ Tâche 10 : Créer des données de test

**Objectif** : Avoir des données pour tester le dashboard

**SQL à exécuter** :
```sql
-- Créer un agent de test pour chaque client existant
INSERT INTO agents (client_id, name, type, status)
SELECT
  id,
  name || ' - Agent 1',
  'inbound',
  'active'
FROM clients
ON CONFLICT DO NOTHING;

-- Mettre à jour quelques appels avec des agent_id
WITH agent_mapping AS (
  SELECT
    c.id as client_id,
    a.id as agent_id
  FROM clients c
  LEFT JOIN agents a ON a.client_id = c.id
  WHERE a.type = 'inbound'
  LIMIT 1
)
UPDATE calls
SET agent_id = (SELECT agent_id FROM agent_mapping WHERE agent_mapping.client_id = calls.client_id)
WHERE agent_id IS NULL
  AND client_id IN (SELECT client_id FROM agent_mapping);

-- Refresh la materialized view avec les nouvelles données
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_call_metrics;
```

**Vérification** :
```sql
-- Vérifier qu'on a des agents
SELECT c.name as client_name, a.name as agent_name, a.type, a.status
FROM agents a
JOIN clients c ON a.client_id = c.id;

-- Vérifier qu'on a des appels avec agents
SELECT COUNT(*), agent_id
FROM calls
GROUP BY agent_id;
```

- [ ] **Confirmé : Données de test créées** (ou décision de ne pas en créer)

---

### Phase 9 : Configuration Auth (20-30 min)

#### ✅ Tâche 11 : Créer un utilisateur de test

**Objectif** : Avoir un user pour tester l'authentification

**Via Supabase Dashboard** :
1. Aller dans Authentication → Users
2. Cliquer sur "Add user"
3. Créer un utilisateur :
   - Email : `test@voipia.com` (ou votre email)
   - Password : Générer un mot de passe fort
   - Auto Confirm : ✅ Oui
4. Copier le `user_id` (UUID)

**Puis dans SQL Editor** :
```sql
-- Assigner des permissions à cet utilisateur
-- Remplacer 'USER_ID_ICI' par le vrai UUID de l'utilisateur

-- Donner accès à tous les clients (pour test)
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  'USER_ID_ICI'::UUID,
  id,
  'admin'
FROM clients
ON CONFLICT DO NOTHING;
```

**Vérification** :
```sql
-- Vérifier les permissions
SELECT
  u.email,
  c.name as client_name,
  ucp.permission_level
FROM user_client_permissions ucp
JOIN auth.users u ON ucp.user_id = u.id
JOIN clients c ON ucp.client_id = c.id;
```

- [ ] **Confirmé : Utilisateur de test créé avec permissions**

---

### Phase 10 : Variables d'Environnement (5 min)

#### ✅ Tâche 12 : Récupérer les credentials Supabase

**Via Supabase Dashboard** :
1. Aller dans Settings → API
2. Copier :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon public key** : `eyJhbGc...` (longue clé)

**Créer/Mettre à jour `.env.local`** dans votre projet :
```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
```

- [ ] **Confirmé : Fichier `.env.local` créé/mis à jour**

---

## ✅ Validation Finale

### Checklist de validation

- [ ] ✅ Toutes les tables créées (`agents`, `user_client_permissions`)
- [ ] ✅ Colonne `agent_id` ajoutée à `calls`
- [ ] ✅ Tous les indexes créés (BRIN + composites)
- [ ] ✅ Materialized view `daily_call_metrics` créée et populée
- [ ] ✅ Fonctions SQL créées (`get_kpi_metrics`, `get_chart_data`)
- [ ] ✅ RLS policies configurées sur toutes les tables
- [ ] ✅ Utilisateur de test créé avec permissions
- [ ] ✅ Variables d'environnement configurées
- [ ] ✅ Backup de la base effectué

### Tests à effectuer

**Test 1 - Tables et données** :
```sql
-- Doit retourner des résultats
SELECT COUNT(*) FROM agents;
SELECT COUNT(*) FROM calls WHERE agent_id IS NOT NULL;
SELECT COUNT(*) FROM daily_call_metrics;
```

**Test 2 - Fonctions** :
```sql
-- Doit retourner du JSON avec des KPIs
SELECT get_kpi_metrics(
  (NOW() - INTERVAL '30 days')::TIMESTAMPTZ,
  NOW()::TIMESTAMPTZ,
  NULL,
  NULL
);

-- Doit retourner du JSON avec des données de charts
SELECT get_chart_data(
  (NOW() - INTERVAL '30 days')::TIMESTAMPTZ,
  NOW()::TIMESTAMPTZ,
  NULL,
  NULL
);
```

**Test 3 - RLS** :
```sql
-- En tant qu'utilisateur connecté, doit voir seulement les clients autorisés
-- (Nécessite d'être connecté via l'app pour vraiment tester)
SELECT * FROM calls LIMIT 10;
```

---

## 🚀 Prochaines Étapes

### Une fois TOUTES les tâches cochées :

1. **Me confirmer** :
   - "J'ai terminé toutes les tâches SQL"
   - Partager un screenshot ou copier/coller des résultats de validation

2. **Je vais développer** :
   - Installation des dépendances npm
   - Création de la structure de composants
   - Configuration TanStack Query
   - Implémentation du layout dashboard
   - Création des filtres
   - Création des KPI cards
   - Création des charts
   - Mise en place de l'authentification côté Next.js

3. **Tests ensemble** :
   - Vérifier que l'authentification fonctionne
   - Vérifier que les données s'affichent correctement
   - Vérifier que les filtres fonctionnent
   - Vérifier que le RLS est respecté

---

## 📞 Support

### Si vous rencontrez un problème

**Problème : Une query SQL échoue**
- Lire le message d'erreur complet
- Me le partager avec le contexte (quelle tâche)
- Je vous fournirai une version corrigée

**Problème : RLS trop restrictif (aucune donnée visible)**
- Temporairement désactiver RLS pour tester :
```sql
ALTER TABLE calls DISABLE ROW LEVEL SECURITY;
```
- Puis réactiver et ajuster les policies

**Problème : Performance lente**
- Vérifier que tous les indexes sont créés
- Exécuter `ANALYZE calls;` pour mettre à jour les statistiques
- Refresh la materialized view

---

## 📝 Notes Importantes

### Attention aux données sensibles
- ⚠️ Ne JAMAIS partager votre `SUPABASE_SERVICE_ROLE_KEY` (seulement anon key)
- ⚠️ Tester les RLS policies avant de déployer en production
- ⚠️ Faire un backup avant toute modification majeure

### Migration future
- Tous les scripts SQL ci-dessus peuvent être sauvegardés en tant que migration
- Créer un fichier `supabase/migrations/20250115_dashboard_setup.sql`
- Permet de reproduire l'installation sur un autre environnement

### Monitoring
- Surveiller les performances des queries dans Supabase Dashboard → Database → Query Performance
- Les BRIN indexes sont optimaux pour vos données time-series
- La materialized view doit être refresh régulièrement

---

**Version** : 1.0
**Date** : 2025-01-15
**Auteur** : Claude Code

**Temps estimé total : 1h30 - 2h00**

---

## 🎉 Félicitations !

Une fois toutes ces tâches complétées, vous aurez :
- ✅ Une base de données optimisée pour analytics
- ✅ Des queries ultra-rapides grâce aux indexes
- ✅ Une sécurité robuste avec RLS
- ✅ Des fonctions SQL réutilisables
- ✅ Une architecture prête pour le dashboard

**Je suis prêt à développer dès que vous aurez terminé !** 🚀
