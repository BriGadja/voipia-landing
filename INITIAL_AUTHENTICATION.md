# INITIAL_AUTHENTICATION.md - Système d'Authentification Dashboard

## 🎯 Vue d'ensemble

Ce document détaille l'architecture complète d'authentification pour sécuriser le dashboard Voipia. Le système utilise **Supabase Auth**, qui gère automatiquement les utilisateurs, mots de passe, tokens JWT, et sessions. Vous n'avez **pas besoin** de créer votre propre système de stockage de mots de passe ou de tokens.

### Objectifs

- **Sécurité** : Seuls les utilisateurs autorisés peuvent accéder au dashboard
- **Multi-tenant** : Chaque utilisateur ne voit que les clients qui lui sont assignés
- **UX fluide** : Login rapide, sessions persistantes, logout propre
- **Production-ready** : Sessions sécurisées, refresh automatique des tokens, protection CSRF

---

## 📋 Architecture d'Authentification

### Comment fonctionne Supabase Auth ?

Supabase Auth est un service d'authentification complet inclus dans Supabase :

**Ce que Supabase Auth gère pour vous** :
- ✅ Stockage sécurisé des mots de passe (bcrypt)
- ✅ Génération et gestion des JWT tokens
- ✅ Refresh automatique des tokens
- ✅ Sessions utilisateur
- ✅ Email de confirmation (optionnel)
- ✅ Reset de mot de passe
- ✅ OAuth providers (Google, GitHub, etc.) - optionnel
- ✅ Protection contre le brute force

**Ce que vous gérez** :
- ❌ Rien au niveau du stockage des credentials
- ✅ Uniquement les **permissions** (qui peut voir quels clients)
- ✅ L'interface de login
- ✅ Le middleware de protection des routes

### Tables Supabase

**Table `auth.users`** (gérée par Supabase Auth) :
- Créée et gérée automatiquement
- Stocke : email, encrypted password, metadata
- Vous n'y touchez jamais directement

**Table `user_client_permissions`** (déjà créée) :
- Lie les users aux clients
- Définit les permissions (read, write, admin)
- C'est **votre** table de business logic

**Table `profiles`** (à créer - optionnel) :
- Informations publiques de l'utilisateur
- Rôle global (admin, user)
- Préférences UI

---

## 🔐 Flow d'Authentification Complet

### 1. Utilisateur non connecté visite `/dashboard`

```
User → /dashboard
       ↓
Middleware vérifie session
       ↓
Pas de session valide
       ↓
Redirect → /login
```

### 2. Page de Login (`/login`)

**Interface** :
```
┌─────────────────────────────────┐
│  🔐 Connexion Dashboard Voipia  │
├─────────────────────────────────┤
│  Email:    [________________]   │
│  Password: [________________]   │
│                                 │
│  [ Se connecter ]               │
│                                 │
│  Mot de passe oublié ?          │
└─────────────────────────────────┘
```

**Code (simplifié)** :
```typescript
// app/login/page.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const router = useRouter()
  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setError(error.message)
      return
    }

    // Succès → redirect vers dashboard
    router.push('/dashboard')
    router.refresh() // Force refresh pour recharger le middleware
  }

  return (
    <form onSubmit={handleLogin}>
      {/* UI de login */}
    </form>
  )
}
```

### 3. Supabase Auth Process (automatique)

```
User submit login form
       ↓
supabase.auth.signInWithPassword()
       ↓
Supabase vérifie email/password
       ↓
Si valide : génère JWT + refresh token
       ↓
Stocke tokens dans cookies httpOnly
       ↓
Retourne session au client
```

**Important** : Les tokens sont stockés dans des **cookies httpOnly** (sécurisés, inaccessibles en JavaScript).

### 4. Middleware vérifie la session

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh session automatiquement
  const { data: { user } } = await supabase.auth.getUser()

  // Si pas de user et route protégée → redirect login
  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Si user existe et est sur /login → redirect dashboard
  if (user && request.nextUrl.pathname === '/login') {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return response
}

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/login',
  ]
}
```

### 5. Accès au Dashboard sécurisé

```
User authentifié → /dashboard
       ↓
Middleware vérifie session (OK)
       ↓
Page charge
       ↓
Server Component fetch data avec RLS
       ↓
PostgreSQL applique les policies RLS
       ↓
User voit UNIQUEMENT ses clients assignés
```

**RLS Policy (déjà créée)** :
```sql
-- L'utilisateur ne voit QUE les appels de ses clients assignés
CREATE POLICY "users_view_their_calls"
  ON calls FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT client_id
      FROM user_client_permissions
      WHERE user_id = auth.uid()  -- ← JWT automatiquement vérifié
    )
  );
```

### 6. Logout

```typescript
// components/LogoutButton.tsx
'use client'

import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export function LogoutButton() {
  const router = useRouter()
  const supabase = createClient()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <button onClick={handleLogout}>
      Déconnexion
    </button>
  )
}
```

---

## 🗂️ Structure des Fichiers

### Nouveaux fichiers à créer

```
app/
├── login/
│   └── page.tsx           # Page de login
├── logout/
│   └── route.ts          # API route pour logout (optionnel)
└── middleware.ts          # Protection des routes (ROOT LEVEL)

components/
└── auth/
    ├── LoginForm.tsx      # Formulaire de login
    └── LogoutButton.tsx   # Bouton déconnexion

lib/
└── auth/
    └── session.ts        # Helpers pour gérer la session
```

### Middleware (IMPORTANT)

Le fichier `middleware.ts` doit être à la **racine du projet**, pas dans `app/` :

```
voipia-landing/
├── app/
├── components/
├── lib/
├── middleware.ts  ← ICI (niveau racine)
├── package.json
└── ...
```

---

## 👤 Gestion des Utilisateurs

### Table `profiles` (à créer)

Cette table stocke les informations publiques de l'utilisateur :

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
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
```

### Trigger de création automatique du profil

Quand un user est créé dans `auth.users`, créer automatiquement son profil :

```sql
-- Function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### Assigner des permissions à un utilisateur

**Scénario** : Vous créez un user et voulez lui donner accès à certains clients.

**Via Supabase Dashboard** :
1. Authentication → Users → Add user
2. Créer l'utilisateur (email + password)
3. Copier le `user_id` (UUID)

**Via SQL** :
```sql
-- Donner accès au client "Voipia" à l'utilisateur
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES (
  '123e4567-e89b-12d3-a456-426614174000',  -- user_id copié
  (SELECT id FROM clients WHERE name = 'Voipia'),
  'admin'
);
```

**Via API (automatisé)** :
```typescript
// app/api/admin/assign-client/route.ts
export async function POST(request: Request) {
  const { userId, clientId, permissionLevel } = await request.json()

  const supabase = createServerClient(...)

  // Vérifier que le user actuel est admin
  const { data: { user } } = await supabase.auth.getUser()
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin') {
    return Response.json({ error: 'Unauthorized' }, { status: 403 })
  }

  // Assigner permission
  const { error } = await supabase
    .from('user_client_permissions')
    .insert({ user_id: userId, client_id: clientId, permission_level: permissionLevel })

  if (error) {
    return Response.json({ error: error.message }, { status: 400 })
  }

  return Response.json({ success: true })
}
```

---

## 🎨 UI/UX d'Authentification

### Page de Login

**Design recommandé** :

```
┌────────────────────────────────────────────┐
│                                            │
│         🔐 Connexion Dashboard             │
│                                            │
│  Accédez à vos statistiques d'agents IA   │
│                                            │
│  ┌────────────────────────────────────┐  │
│  │ Email                              │  │
│  │ [____________________________]     │  │
│  │                                    │  │
│  │ Mot de passe                       │  │
│  │ [____________________________] 👁  │  │
│  │                                    │  │
│  │ [ Se connecter ]                   │  │
│  │                                    │  │
│  │ Mot de passe oublié ?              │  │
│  └────────────────────────────────────┘  │
│                                            │
│  ⚠️ Si erreur : "Email ou mot de passe    │
│     incorrect"                             │
└────────────────────────────────────────────┘
```

**Fonctionnalités** :
- ✅ Validation email format
- ✅ Toggle show/hide password
- ✅ Loading state pendant login
- ✅ Messages d'erreur clairs
- ✅ Responsive mobile
- ✅ Lien "Mot de passe oublié" (vers `/reset-password`)

### Bouton Logout dans le Dashboard

**Emplacement** : Header du dashboard, en haut à droite

```typescript
<header className="flex justify-between items-center mb-8">
  <div>
    <h1>Dashboard Analytics</h1>
    <p className="text-sm text-white/60">
      Connecté en tant que {user.email}
    </p>
  </div>

  <LogoutButton />
</header>
```

---

## 🔒 Sécurité Best Practices

### 1. Variables d'environnement

**Ne JAMAIS commiter** :
- ❌ Service role key (admin access)
- ❌ Database passwords

**Peut être public** (déjà dans votre code) :
- ✅ `NEXT_PUBLIC_SUPABASE_URL`
- ✅ `NEXT_PUBLIC_SUPABASE_ANON_KEY` (lecture seule avec RLS)

### 2. Row Level Security (RLS)

**OBLIGATOIRE sur toutes les tables** :
```sql
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_client_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
```

Sans RLS, même avec authentification, **tous les users pourraient voir toutes les données**.

### 3. JWT Validation

Le middleware utilise `getUser()` qui :
- ✅ Vérifie la signature du JWT
- ✅ Vérifie l'expiration
- ✅ Refresh automatiquement si nécessaire
- ✅ Retourne `null` si invalide

**Ne JAMAIS utiliser** `getSession()` seul :
```typescript
// ❌ MAUVAIS - Ne vérifie pas le JWT côté serveur
const { data: { session } } = await supabase.auth.getSession()

// ✅ BON - Vérifie le JWT avec la clé secrète
const { data: { user } } = await supabase.auth.getUser()
```

### 4. HTTPS en production

Les cookies `httpOnly` et `secure` nécessitent HTTPS. En dev (localhost), HTTP est OK.

### 5. Rate Limiting (optionnel)

Protéger contre le brute force sur `/login` :

**Option A** : Supabase Auth inclut déjà un rate limiting basique

**Option B** : Ajouter Vercel Rate Limiting :
```typescript
import { ratelimit } from '@/lib/ratelimit'

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown'
  const { success } = await ratelimit.limit(ip)

  if (!success) {
    return Response.json({ error: 'Too many requests' }, { status: 429 })
  }

  // ... login logic
}
```

---

## 🧪 Tests d'Authentification

### Scénarios à tester

**Test 1 - Login réussi** :
1. Créer un user de test dans Supabase
2. Aller sur `/login`
3. Entrer email/password valides
4. Vérifier redirect vers `/dashboard`
5. Vérifier que les données s'affichent

**Test 2 - Login échoué** :
1. Aller sur `/login`
2. Entrer mauvais password
3. Vérifier message d'erreur
4. Vérifier pas de redirect

**Test 3 - Accès direct sans auth** :
1. En navigation privée (pas de session)
2. Aller directement sur `/dashboard`
3. Vérifier redirect vers `/login`

**Test 4 - RLS** :
1. Se connecter avec user A (accès client X)
2. Vérifier qu'on voit seulement les données du client X
3. Se déconnecter
4. Se connecter avec user B (accès client Y)
5. Vérifier qu'on voit seulement les données du client Y

**Test 5 - Logout** :
1. Se connecter
2. Cliquer sur Logout
3. Vérifier redirect vers `/login`
4. Essayer d'accéder à `/dashboard` → doit redirect vers `/login`

**Test 6 - Session refresh** :
1. Se connecter
2. Attendre 1 heure (ou modifier l'expiration JWT pour tester)
3. Naviguer dans le dashboard
4. Vérifier que la session se refresh automatiquement

---

## 📊 Flow Diagrams

### Diagramme de Séquence : Premier Login

```
User          Browser         Next.js         Supabase Auth      PostgreSQL
 |               |               |                  |                 |
 |--Visit /dashboard------------>|                  |                 |
 |               |               |                  |                 |
 |               |<---Middleware checks session-----|                 |
 |               |               |                  |                 |
 |               |<--No session, redirect /login----|                 |
 |               |               |                  |                 |
 |--Enter credentials----------->|                  |                 |
 |               |               |                  |                 |
 |               |--signInWithPassword------------->|                 |
 |               |               |                  |                 |
 |               |               |                  |--Verify hash--->|
 |               |               |                  |<--User valid----|
 |               |               |                  |                 |
 |               |               |<--JWT + cookies--|                 |
 |               |               |                  |                 |
 |<--Redirect /dashboard---------|                  |                 |
 |               |               |                  |                 |
 |--Visit /dashboard------------>|                  |                 |
 |               |               |                  |                 |
 |               |<---Middleware verifies JWT------>|                 |
 |               |               |                  |                 |
 |               |--Fetch data with user context------------------->|
 |               |               |                  |                 |
 |               |               |<--RLS filtered data---------------|
 |               |               |                  |                 |
 |<--Dashboard renders-----------|                  |                 |
```

### Diagramme de Flow : Décisions du Middleware

```
                    Request arrives
                           ↓
                    Extract cookies
                           ↓
              ┌────────────┴────────────┐
              │   supabase.auth.getUser() │
              └────────────┬────────────┘
                           ↓
                   User exists?
                ┌──────────┴──────────┐
                │                     │
               YES                   NO
                │                     │
                ↓                     ↓
        Is on /login?         Is on protected route?
        ┌──────┴──────┐      ┌──────┴──────┐
       YES            NO     YES            NO
        │              │      │              │
        ↓              ↓      ↓              ↓
   Redirect      Allow    Redirect      Allow
   /dashboard    access   /login        access
```

---

## 🚀 Roadmap d'Implémentation

### Phase 1 : Setup Supabase Auth (30 min)

1. **Créer la table `profiles`** (SQL)
2. **Créer le trigger `handle_new_user`** (SQL)
3. **Créer un utilisateur de test** (Supabase Dashboard)
4. **Lui assigner un client** (SQL)

### Phase 2 : Pages d'Authentification (2h)

1. **Créer `/app/login/page.tsx`**
2. **Créer `LoginForm` component**
3. **Créer `LogoutButton` component**
4. **Tester le login/logout**

### Phase 3 : Middleware (1h)

1. **Créer `/middleware.ts`**
2. **Tester la protection de `/dashboard`**
3. **Tester le redirect automatique**

### Phase 4 : UX Polish (1h)

1. **Ajouter loading states**
2. **Ajouter error handling**
3. **Ajouter "Mot de passe oublié"** (optionnel)
4. **Responsive design**

### Phase 5 : Tests (1h)

1. **Tester tous les scénarios**
2. **Vérifier RLS**
3. **Tester en navigation privée**

**Temps total estimé : 5-6 heures**

---

## ⚠️ Points Importants

### 1. Pas besoin de gérer les passwords

Supabase Auth fait tout :
- ✅ Hashing bcrypt automatique
- ✅ Salt unique par user
- ✅ Validation de force de password (configurable)
- ✅ Protection brute force

Vous ne touchez **JAMAIS** aux passwords en clair.

### 2. Les JWT sont automatiques

Quand un user se connecte :
1. Supabase génère un JWT signé
2. Le JWT contient : `user_id`, `email`, `role`, `exp`
3. Le JWT est stocké dans un cookie `httpOnly`
4. PostgreSQL peut lire le JWT via `auth.uid()`

### 3. RLS est la clé de la sécurité

Même si un user modifie le frontend en JavaScript, les RLS policies PostgreSQL l'empêchent de voir des données non autorisées.

```sql
-- Cette policy s'applique TOUJOURS, même si le code frontend est hacké
CREATE POLICY "users_view_their_calls"
  ON calls FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT client_id FROM user_client_permissions
      WHERE user_id = auth.uid()  -- Vérifié par PostgreSQL
    )
  );
```

### 4. Middleware vs RLS

**Middleware** :
- Empêche l'accès à la **page** `/dashboard`
- Redirect vers `/login` si pas connecté
- UX (évite de charger la page pour rien)

**RLS** :
- Empêche l'accès aux **données** dans PostgreSQL
- Sécurité (même si middleware bypassé)
- OBLIGATOIRE

Les deux sont nécessaires et complémentaires.

---

## 📝 Fichier de Configuration

### Supabase Dashboard Settings

**Auth Settings à configurer** :

1. **Email Auth** : ✅ Activé (par défaut)
2. **Email Confirmation** : ❌ Désactivé (ou ✅ si vous voulez)
3. **Password Requirements** :
   - Minimum length : 8 caractères
   - Require uppercase : Optionnel
   - Require numbers : Recommandé
4. **Session Settings** :
   - JWT Expiry : 3600 (1 heure)
   - Refresh Token Expiry : 2592000 (30 jours)

**Accès** : Supabase Dashboard → Authentication → Settings

---

## 🎯 Exemple Complet : Création d'un Utilisateur

### Étape 1 : Créer l'utilisateur dans Supabase

**Via Dashboard** :
1. Authentication → Users → Add user
2. Email : `jean.dupont@example.com`
3. Password : `SecurePass123!`
4. Auto Confirm : ✅ Oui
5. Créer

**Le trigger `handle_new_user` créera automatiquement le profil**.

### Étape 2 : Assigner des permissions

```sql
-- Trouver l'user_id
SELECT id, email FROM auth.users WHERE email = 'jean.dupont@example.com';

-- Résultat : id = 'abc-123-def-456'

-- Assigner accès au client "Voipia"
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES (
  'abc-123-def-456',
  (SELECT id FROM clients WHERE name = 'Voipia'),
  'read'
);

-- Assigner accès à un second client "Exotic Design"
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES (
  'abc-123-def-456',
  (SELECT id FROM clients WHERE name = 'Exotic Design'),
  'admin'
);
```

### Étape 3 : L'utilisateur se connecte

1. Va sur `/login`
2. Entre `jean.dupont@example.com` / `SecurePass123!`
3. Clique "Se connecter"
4. Est redirecté vers `/dashboard`
5. Voit **uniquement** les données de "Voipia" et "Exotic Design"

---

## ✅ Checklist de Production

Avant de déployer en production :

- [ ] RLS activé sur **toutes** les tables
- [ ] Policies testées avec différents users
- [ ] Middleware protège toutes les routes sensibles
- [ ] HTTPS activé (Vercel le fait automatiquement)
- [ ] Variables d'environnement configurées sur Vercel
- [ ] Email confirmation activé (si souhaité)
- [ ] Rate limiting configuré (optionnel)
- [ ] Logs d'authentification monitorés
- [ ] Backup régulier de `user_client_permissions`

---

## 🆘 Troubleshooting

### Problème : "Redirect loop entre /login et /dashboard"

**Cause** : Le middleware ne détecte pas correctement l'utilisateur.

**Solution** :
```typescript
// Utiliser getUser() pas getSession()
const { data: { user } } = await supabase.auth.getUser()  // ✅
// PAS
const { data: { session } } = await supabase.auth.getSession()  // ❌
```

### Problème : "User connecté mais voit aucune donnée"

**Cause** : Pas de permissions assignées dans `user_client_permissions`.

**Solution** :
```sql
-- Vérifier les permissions
SELECT * FROM user_client_permissions WHERE user_id = 'user-id-here';

-- Si vide, assigner
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
VALUES ('user-id', 'client-id', 'read');
```

### Problème : "Token expired"

**Cause** : Le refresh du token a échoué.

**Solution** : Le middleware gère normalement le refresh automatiquement. Si problème persiste :
```typescript
// Forcer un refresh
await supabase.auth.refreshSession()
```

### Problème : "CORS error" sur login

**Cause** : Configuration Supabase Auth.

**Solution** : Aller dans Supabase → Authentication → URL Configuration → Ajouter `http://localhost:3000` dans "Redirect URLs"

---

## 📚 Ressources

**Documentation Officielle** :
- Supabase Auth : https://supabase.com/docs/guides/auth
- Next.js 15 + Supabase : https://supabase.com/docs/guides/auth/server-side/nextjs
- RLS : https://supabase.com/docs/guides/auth/row-level-security
- JWT : https://supabase.com/docs/guides/auth/jwts

**Exemples** :
- Template Next.js + Supabase : https://github.com/vercel/next.js/tree/canary/examples/with-supabase

---

**Version** : 1.0
**Date** : 2025-01-15
**Auteur** : Voipia Team
