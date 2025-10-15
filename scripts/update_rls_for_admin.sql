-- =====================================================
-- Mise à jour des policies RLS pour gérer les admins
-- =====================================================
--
-- Les utilisateurs avec role='admin' dans profiles voient TOUT
-- Les utilisateurs normaux voient uniquement leurs clients autorisés via user_client_permissions
--
-- À exécuter dans l'éditeur SQL de Supabase Dashboard
-- =====================================================

-- 1. CLIENTS : Modifier la policy pour inclure les admins
DROP POLICY IF EXISTS "users_view_their_clients" ON clients;

CREATE POLICY "users_view_their_clients" ON clients
FOR SELECT
USING (
  -- Soit l'utilisateur est admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  -- Soit l'utilisateur a une permission spécifique sur ce client
  OR id IN (
    SELECT client_id FROM user_client_permissions
    WHERE user_id = auth.uid()
  )
);

-- 2. AGENTS : Modifier la policy pour inclure les admins
DROP POLICY IF EXISTS "users_view_their_agents" ON agents;

CREATE POLICY "users_view_their_agents" ON agents
FOR SELECT
USING (
  -- Soit l'utilisateur est admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  -- Soit l'utilisateur a une permission sur le client de cet agent
  OR client_id IN (
    SELECT client_id FROM user_client_permissions
    WHERE user_id = auth.uid()
  )
);

-- 3. CALLS : Modifier la policy de lecture pour inclure les admins
DROP POLICY IF EXISTS "users_view_their_calls" ON calls;

CREATE POLICY "users_view_their_calls" ON calls
FOR SELECT
USING (
  -- Soit l'utilisateur est admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  -- Soit l'utilisateur a une permission sur le client de cet appel
  OR client_id IN (
    SELECT client_id FROM user_client_permissions
    WHERE user_id = auth.uid()
  )
);

-- 4. CALLS : Modifier la policy d'insertion pour inclure les admins
DROP POLICY IF EXISTS "users_insert_to_their_clients" ON calls;

CREATE POLICY "users_insert_to_their_clients" ON calls
FOR INSERT
WITH CHECK (
  -- Soit l'utilisateur est admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  -- Soit l'utilisateur a une permission write/admin sur ce client
  OR client_id IN (
    SELECT client_id FROM user_client_permissions
    WHERE user_id = auth.uid()
    AND permission_level IN ('write', 'admin')
  )
);

-- 5. USER_CLIENT_PERMISSIONS : Les admins peuvent voir toutes les permissions (optionnel)
DROP POLICY IF EXISTS "users_view_own_permissions" ON user_client_permissions;

CREATE POLICY "users_view_permissions" ON user_client_permissions
FOR SELECT
USING (
  -- Soit l'utilisateur est admin (voit toutes les permissions)
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
  -- Soit l'utilisateur voit uniquement ses propres permissions
  OR user_id = auth.uid()
);

-- =====================================================
-- VÉRIFICATIONS
-- =====================================================

-- Vérifier les policies créées
SELECT
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('clients', 'agents', 'calls', 'user_client_permissions')
ORDER BY tablename, policyname;

-- Compter les admins actuels
SELECT
  email,
  full_name,
  role,
  created_at
FROM profiles
WHERE role = 'admin'
ORDER BY email;
