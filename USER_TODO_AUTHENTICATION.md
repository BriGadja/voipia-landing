# USER TODO - Configuration Authentification Supabase

Ce document liste **toutes les tâches que vous devez effectuer dans Supabase** pour mettre en place l'authentification du dashboard. Ces étapes sont nécessaires avant que je puisse créer le middleware, la page de login, et les composants d'authentification.

---

## 📋 Vue d'ensemble

**Pourquoi ces tâches ?**
- Configuration de Supabase Auth (email/password)
- Création de la table `profiles` pour les infos utilisateur
- Configuration d'un trigger automatique
- Création d'utilisateurs de test
- Configuration des permissions

**Temps estimé : 45 minutes - 1 heure**

---

## 🎯 Checklist des Tâches

### Phase 1 : Configuration Supabase Auth (10 min)

#### ✅ Tâche 1 : Activer Email Auth

**Objectif** : S'assurer que l'authentification par email/password est activée

**Via Supabase Dashboard** :
1. Aller dans **Authentication** → **Providers**
2. Vérifier que **Email** est activé (normalement activé par défaut)
3. Si pas activé, cliquer sur **Email** et activer

**Settings recommandés** :
- Enable Email provider : ✅ **ON**
- Confirm email : ❌ **OFF** (pour simplifier les tests)
  - ⚠️ En production, vous voudrez probablement activer ceci
- Enable email confirmations : ❌ **OFF** (pour l'instant)

- [ ] **Confirmé : Email Auth activé**

---

#### ✅ Tâche 2 : Configurer les URLs de redirection

**Objectif** : Autoriser les redirections après login

**Via Supabase Dashboard** :
1. Aller dans **Authentication** → **URL Configuration**
2. Dans **Redirect URLs**, ajouter :
   ```
   http://localhost:3000/dashboard
   http://localhost:3000/
   ```
3. Si vous avez une URL de production, ajoutez aussi :
   ```
   https://votre-domaine.com/dashboard
   https://votre-domaine.com/
   ```
4. Cliquer sur **Save**

- [ ] **Confirmé : Redirect URLs configurées**

---

#### ✅ Tâche 3 : Configurer les paramètres de sécurité

**Objectif** : Définir la force des mots de passe et la durée des sessions

**Via Supabase Dashboard** :
1. Aller dans **Authentication** → **Settings**
2. **Password Settings** :
   - Minimum password length : **8** (recommandé)
   - Password strength : **Fair** ou **Good**
3. **Session Settings** :
   - JWT expiry time : **3600** secondes (1 heure)
   - Refresh token expiry : **2592000** secondes (30 jours)
4. Cliquer sur **Save**

- [ ] **Confirmé : Paramètres de sécurité configurés**

---

### Phase 2 : Table `profiles` et Trigger (15 min)

#### ✅ Tâche 4 : Créer la table `profiles`

**Objectif** : Stocker les informations publiques des utilisateurs (nom, rôle, etc.)

**Via Supabase Dashboard → SQL Editor** :

```sql
-- Créer la table profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_updated_at();

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy : Les users voient leur propre profil
CREATE POLICY "users_view_own_profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Policy : Les users peuvent update leur propre profil
CREATE POLICY "users_update_own_profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Policy : Les admins voient tous les profils
CREATE POLICY "admins_view_all_profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

COMMENT ON TABLE profiles IS 'Profils utilisateurs avec informations publiques';
```

**Vérification** :
```sql
-- Doit afficher la structure de la table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
```

- [ ] **Confirmé : Table `profiles` créée avec succès**

---

#### ✅ Tâche 5 : Créer le trigger de création automatique

**Objectif** : Quand un utilisateur est créé dans `auth.users`, créer automatiquement son profil

**Via Supabase Dashboard → SQL Editor** :

```sql
-- Function pour créer automatiquement un profil
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log l'erreur mais ne bloque pas la création de l'utilisateur
    RAISE WARNING 'Could not create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Trigger sur auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION public.handle_new_user IS 'Crée automatiquement un profil quand un user est créé';
```

**Vérification** :
```sql
-- Doit afficher le trigger
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

- [ ] **Confirmé : Trigger `on_auth_user_created` créé et actif**

---

### Phase 3 : Utilisateurs de Test (15 min)

#### ✅ Tâche 6 : Créer un utilisateur admin

**Objectif** : Créer votre compte principal qui aura accès à tout

**Via Supabase Dashboard** :
1. Aller dans **Authentication** → **Users**
2. Cliquer sur **Add user** → **Create new user**
3. Remplir :
   - **Email** : `admin@voipia.com` (ou votre email)
   - **Password** : Choisir un mot de passe fort (min 8 caractères)
   - **Auto Confirm User** : ✅ **Coché** (important pour éviter la confirmation email)
4. Cliquer sur **Create user**
5. **Copier le User ID (UUID)** qui apparaît dans la liste

**Puis dans SQL Editor** :
```sql
-- Remplacer 'VOTRE_USER_ID_ICI' par l'UUID copié
UPDATE profiles
SET role = 'admin', full_name = 'Admin Voipia'
WHERE id = 'VOTRE_USER_ID_ICI';

-- Vérifier
SELECT id, email, role, full_name FROM profiles WHERE role = 'admin';
```

- [ ] **Confirmé : Utilisateur admin créé**
- [ ] **User ID copié** : `_______________________________________`

---

#### ✅ Tâche 7 : Assigner tous les clients à l'admin

**Objectif** : L'admin doit voir tous les clients

**Via SQL Editor** :
```sql
-- Remplacer 'ADMIN_USER_ID' par l'UUID de l'admin
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  'ADMIN_USER_ID'::UUID,
  id,
  'admin'
FROM clients
ON CONFLICT (user_id, client_id) DO NOTHING;

-- Vérifier
SELECT
  p.email,
  c.name as client_name,
  ucp.permission_level
FROM user_client_permissions ucp
JOIN profiles p ON ucp.user_id = p.id
JOIN clients c ON ucp.client_id = c.id
WHERE p.role = 'admin';
```

**Résultat attendu** : L'admin doit avoir une ligne pour chaque client avec `permission_level = 'admin'`

- [ ] **Confirmé : Admin a accès à tous les clients**

---

#### ✅ Tâche 8 : Créer un utilisateur standard (optionnel)

**Objectif** : Créer un deuxième utilisateur pour tester les permissions

**Via Supabase Dashboard** :
1. **Authentication** → **Users** → **Add user**
2. Remplir :
   - **Email** : `user@voipia.com`
   - **Password** : `TestUser123!`
   - **Auto Confirm User** : ✅ **Coché**
3. **Copier le User ID**

**Puis dans SQL Editor** :
```sql
-- Remplacer 'USER_ID_ICI' par l'UUID copié
UPDATE profiles
SET full_name = 'User Test'
WHERE id = 'USER_ID_ICI';

-- Assigner accès à un seul client (par exemple "Voipia")
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES (
  'USER_ID_ICI'::UUID,
  (SELECT id FROM clients WHERE name = 'Voipia' LIMIT 1),
  'read'
);

-- Vérifier
SELECT
  p.email,
  c.name as client_name,
  ucp.permission_level
FROM user_client_permissions ucp
JOIN profiles p ON ucp.user_id = p.id
JOIN clients c ON ucp.client_id = c.id
WHERE p.email = 'user@voipia.com';
```

**Résultat attendu** : Le user standard doit avoir accès à 1 seul client avec `permission_level = 'read'`

- [ ] **Confirmé : Utilisateur standard créé** (optionnel)
- [ ] **User ID copié** : `_______________________________________` (optionnel)

---

### Phase 4 : Vérifications Finales (5 min)

#### ✅ Tâche 9 : Tester la création automatique de profil

**Objectif** : Vérifier que le trigger fonctionne

**Test** :
1. Créer un nouvel utilisateur via Dashboard (email : `test@example.com`)
2. Exécuter dans SQL Editor :
```sql
-- Doit retourner une ligne avec le profil auto-créé
SELECT
  u.id,
  u.email as auth_email,
  p.email as profile_email,
  p.full_name,
  p.role
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE u.email = 'test@example.com';
```

**Résultat attendu** :
- `profile_email` = `test@example.com`
- `role` = `user` (par défaut)

- [ ] **Confirmé : Trigger de création automatique fonctionne**

---

#### ✅ Tâche 10 : Vérifier les RLS policies

**Objectif** : S'assurer que les policies sont actives

**Via SQL Editor** :
```sql
-- Doit retourner les policies sur profiles
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;
```

**Résultat attendu** : Au moins 3 policies :
- `users_view_own_profile`
- `users_update_own_profile`
- `admins_view_all_profiles`

- [ ] **Confirmé : RLS policies actives sur `profiles`**

---

#### ✅ Tâche 11 : Vérifier que RLS est activé partout

**Objectif** : S'assurer que TOUTES les tables sensibles ont RLS

**Via SQL Editor** :
```sql
-- Doit afficher toutes les tables avec RLS enabled = true
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('calls', 'clients', 'agents', 'user_client_permissions', 'profiles')
ORDER BY tablename;
```

**Résultat attendu** : Toutes les tables doivent avoir `rowsecurity = true`

Si une table a `rowsecurity = false`, exécuter :
```sql
ALTER TABLE nom_de_la_table ENABLE ROW LEVEL SECURITY;
```

- [ ] **Confirmé : RLS activé sur toutes les tables sensibles**

---

### Phase 5 : Configuration Email (Optionnel - 5 min)

#### ✅ Tâche 12 : Configurer les templates d'email (OPTIONNEL)

**Objectif** : Personnaliser les emails de confirmation, reset password, etc.

**Via Supabase Dashboard** :
1. Aller dans **Authentication** → **Email Templates**
2. Pour chaque template (Confirm signup, Reset password, etc.) :
   - Personnaliser le **Subject**
   - Personnaliser le **Body**
   - Utiliser les variables : `{{ .ConfirmationURL }}`, `{{ .Email }}`, etc.

**Exemple de template "Confirm signup"** :
```
Subject: Confirmez votre compte Voipia Dashboard

Body:
Bonjour,

Bienvenue sur le Dashboard Voipia !

Veuillez confirmer votre adresse email en cliquant sur le lien ci-dessous :

{{ .ConfirmationURL }}

Si vous n'avez pas créé de compte, vous pouvez ignorer cet email.

Cordialement,
L'équipe Voipia
```

- [ ] **Confirmé : Templates d'email configurés** (optionnel)

---

## ✅ Validation Finale

### Checklist complète

- [ ] ✅ Email Auth activé
- [ ] ✅ Redirect URLs configurées
- [ ] ✅ Paramètres de sécurité configurés
- [ ] ✅ Table `profiles` créée avec RLS
- [ ] ✅ Trigger `on_auth_user_created` actif
- [ ] ✅ Utilisateur admin créé et configuré
- [ ] ✅ Admin a accès à tous les clients
- [ ] ✅ Utilisateur standard créé (optionnel)
- [ ] ✅ Trigger testé et fonctionnel
- [ ] ✅ RLS policies vérifiées
- [ ] ✅ RLS activé sur toutes les tables

### Tests finaux à effectuer

**Test 1 - Création automatique de profil** :
```sql
-- Créer un user via Dashboard et vérifier
SELECT * FROM profiles WHERE email = 'nouvel-user@test.com';
-- Doit retourner une ligne
```

**Test 2 - Permissions admin** :
```sql
-- Vérifier que l'admin voit tous les clients
SELECT COUNT(*) as nb_clients_accessibles
FROM user_client_permissions
WHERE user_id = 'ADMIN_USER_ID';

-- Doit être égal au nombre total de clients
SELECT COUNT(*) as nb_clients_total FROM clients;
```

**Test 3 - Permissions user standard** :
```sql
-- Vérifier qu'un user standard ne voit QUE ses clients assignés
SELECT COUNT(*) as nb_clients_accessibles
FROM user_client_permissions
WHERE user_id = 'USER_STANDARD_ID';

-- Doit être < au nombre total de clients
```

**Test 4 - RLS** :
```sql
-- Toutes ces tables doivent avoir rowsecurity = true
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('calls', 'clients', 'agents', 'user_client_permissions', 'profiles');
```

---

## 📝 Informations à Noter

**Credentials de l'admin** :
- Email : `brice@voipia.fr`
- Password : `Amidala060391!`
- User ID : `b2584177-c972-49c6-9266-579b52a2b833`

**Credentials du user standard** (optionnel) :
- Email : `user@voipia.fr`
- Password : `TestUser123!`
- User ID : `b0319354-852d-42d2-a6b3-e51a613a7033`

**URLs configurées** :
- Localhost : `http://localhost:3000/dashboard`
- Production : `https://www.voipia.fr/dashboard`

---

## 🚀 Prochaines Étapes

### Une fois TOUTES les tâches cochées :

1. **Me confirmer** :
   - "J'ai terminé toutes les tâches d'authentification"
   - Partager les credentials de l'admin (en sécurité)
   - Confirmer que le trigger fonctionne

2. **Je vais développer** :
   - Middleware de protection (`/middleware.ts`)
   - Page de login (`/app/login/page.tsx`)
   - Composant LoginForm
   - Composant LogoutButton
   - Integration dans le dashboard

3. **Tests ensemble** :
   - Login avec l'admin → doit voir tous les clients
   - Login avec le user standard → doit voir 1 seul client
   - Logout → doit redirect vers login
   - Accès direct à /dashboard sans auth → doit redirect vers login

---

## 📞 Support

### Si vous rencontrez un problème

**Problème : Le trigger ne se crée pas**
- Vérifier que vous êtes bien dans le schema `public`
- Vérifier les permissions de la function

**Problème : Le profil n'est pas créé automatiquement**
- Vérifier que le trigger existe :  
```sql
SELECT * FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created';
```
- Supprimer le user créé et recréer pour tester

**Problème : RLS trop restrictif**
- Temporairement désactiver pour tester :
```sql
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```
- Puis réactiver et ajuster les policies

**Problème : Cannot create user**
- Vérifier que Email Auth est activé
- Vérifier la force du mot de passe
- Vérifier les logs dans Dashboard → Logs

---

## 🎉 Félicitations !

Une fois ces tâches complétées, vous aurez :
- ✅ Un système d'authentification sécurisé
- ✅ Des utilisateurs avec rôles et permissions
- ✅ Une isolation complète des données par client
- ✅ Un système évolutif et production-ready

**Je suis prêt à créer le middleware et les pages de login dès que vous aurez terminé !** 🚀

---

**Version** : 1.0
**Date** : 2025-01-15
**Temps estimé** : 45 min - 1 heure
**Auteur** : Claude Code
