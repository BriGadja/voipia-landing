# Gestion des Permissions Utilisateurs

## Structure du système

Les permissions sont gérées via la table `user_client_permissions` qui associe :
- Un utilisateur (`user_id`)
- Un client (`client_id`)
- Un niveau de permission (`permission_level`)

**Important** : Les permissions sont au niveau CLIENT, pas AGENT. Un utilisateur avec accès à un client voit automatiquement tous les agents de ce client.

## Niveaux de permission

- `read` : Lecture seule (voir les statistiques)
- `write` : Lecture + écriture (peut modifier les données)
- `admin` : Tous les droits sur le client

## État actuel

### Clients disponibles
- **Exotic Design** (Mobilier) - ID: `35f679b2-8709-4fac-a783-bb586f64ed59`
- **Norloc** (Immobilier) - ID: `e63beaf9-2e3c-44e9-8f5d-5d063cac82fd`
- **Stefano Design** (Mobilier) - ID: `c00829be-33a9-4296-9bb2-810fd25baa54`
- **Voipia** (IA) - ID: `4bb95004-1957-4cec-b10b-64e741d1d197`

### Utilisateurs
- `brice@voipia.fr` - Admin sur tous les clients
- `user@voipia.fr` - Read sur Voipia uniquement
- `brice.gachadoat@gmail.com` - Aucune permission
- `test@example.com` - Aucune permission

## Requêtes SQL pour gérer les permissions

### 1. Voir toutes les permissions existantes

```sql
SELECT
  p.email,
  p.full_name,
  c.name as client_name,
  ucp.permission_level,
  ucp.created_at
FROM user_client_permissions ucp
JOIN profiles p ON ucp.user_id = p.id
JOIN clients c ON ucp.client_id = c.id
ORDER BY p.email, c.name;
```

### 2. Voir les permissions d'un utilisateur spécifique

```sql
-- Remplacez 'email@example.com' par l'email de l'utilisateur
SELECT
  c.name as client_name,
  ucp.permission_level,
  COUNT(a.id) as nombre_agents
FROM user_client_permissions ucp
JOIN profiles p ON ucp.user_id = p.id
JOIN clients c ON ucp.client_id = c.id
LEFT JOIN agents a ON c.id = a.client_id
WHERE p.email = 'email@example.com'
GROUP BY c.name, ucp.permission_level
ORDER BY c.name;
```

### 3. Donner accès à UN client à un utilisateur

```sql
-- Exemple : Donner accès READ à user@voipia.fr sur Exotic Design
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'read' as permission_level
FROM profiles p, clients c
WHERE p.email = 'user@voipia.fr'
  AND c.name = 'Exotic Design';
```

### 4. Donner accès à PLUSIEURS clients à un utilisateur

```sql
-- Exemple : Donner accès READ à test@example.com sur Exotic Design ET Norloc
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'read' as permission_level
FROM profiles p
CROSS JOIN clients c
WHERE p.email = 'test@example.com'
  AND c.name IN ('Exotic Design', 'Norloc');
```

### 5. Donner accès à TOUS les clients à un utilisateur

```sql
-- Exemple : Donner accès ADMIN à brice.gachadoat@gmail.com sur TOUS les clients
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'admin' as permission_level
FROM profiles p
CROSS JOIN clients c
WHERE p.email = 'brice.gachadoat@gmail.com';
```

### 6. Modifier le niveau de permission d'un utilisateur

```sql
-- Exemple : Passer user@voipia.fr de READ à ADMIN sur Voipia
UPDATE user_client_permissions ucp
SET permission_level = 'admin'
FROM profiles p, clients c
WHERE ucp.user_id = p.id
  AND ucp.client_id = c.id
  AND p.email = 'user@voipia.fr'
  AND c.name = 'Voipia';
```

### 7. Retirer l'accès d'un utilisateur à un client

```sql
-- Exemple : Retirer l'accès de user@voipia.fr à Voipia
DELETE FROM user_client_permissions ucp
USING profiles p, clients c
WHERE ucp.user_id = p.id
  AND ucp.client_id = c.id
  AND p.email = 'user@voipia.fr'
  AND c.name = 'Voipia';
```

### 8. Retirer tous les accès d'un utilisateur

```sql
-- Exemple : Retirer tous les accès de test@example.com
DELETE FROM user_client_permissions ucp
USING profiles p
WHERE ucp.user_id = p.id
  AND p.email = 'test@example.com';
```

### 9. Voir les utilisateurs qui n'ont aucun accès

```sql
SELECT
  p.email,
  p.full_name,
  p.role,
  p.created_at
FROM profiles p
LEFT JOIN user_client_permissions ucp ON p.id = ucp.user_id
WHERE ucp.user_id IS NULL
ORDER BY p.created_at DESC;
```

### 10. Copier les permissions d'un utilisateur vers un autre

```sql
-- Exemple : Copier toutes les permissions de brice@voipia.fr vers nouveau@voipia.fr
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p_new.id as user_id,
  ucp_existing.client_id,
  ucp_existing.permission_level
FROM user_client_permissions ucp_existing
JOIN profiles p_existing ON ucp_existing.user_id = p_existing.id
CROSS JOIN profiles p_new
WHERE p_existing.email = 'brice@voipia.fr'
  AND p_new.email = 'nouveau@voipia.fr';
```

## Workflow recommandé

### Pour créer un nouvel utilisateur avec accès

1. **Créer l'utilisateur dans Supabase Authentication**
   - Dashboard → Authentication → Users → Add user
   - Cocher "Send email invitation"

2. **Attendre que l'utilisateur se connecte** (création automatique du profil)

3. **Donner les permissions** via SQL :
   ```sql
   INSERT INTO user_client_permissions (user_id, client_id, permission_level)
   SELECT
     p.id as user_id,
     c.id as client_id,
     'read' as permission_level
   FROM profiles p, clients c
   WHERE p.email = 'nouvel-utilisateur@example.com'
     AND c.name = 'Nom du Client';
   ```

4. **Vérifier l'accès**
   - L'utilisateur se connecte sur le dashboard
   - Il ne voit que les données des clients auxquels il a accès

## Exemples pratiques

### Donner accès à un client sur son propre agent

```sql
-- Client "Exotic Design" veut voir son propre dashboard
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'read' as permission_level
FROM profiles p, clients c
WHERE p.email = 'contact@exoticdesign.com'
  AND c.name = 'Exotic Design';
```

### Donner accès admin à un super-utilisateur

```sql
-- Nouvel administrateur Voipia qui doit tout voir
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'admin' as permission_level
FROM profiles p
CROSS JOIN clients c
WHERE p.email = 'admin@voipia.fr';
```

### Donner accès à plusieurs clients (commercial)

```sql
-- Un commercial qui gère Exotic Design et Stefano Design
INSERT INTO user_client_permissions (user_id, client_id, permission_level)
SELECT
  p.id as user_id,
  c.id as client_id,
  'write' as permission_level
FROM profiles p
CROSS JOIN clients c
WHERE p.email = 'commercial@voipia.fr'
  AND c.name IN ('Exotic Design', 'Stefano Design');
```

## Vérifications importantes

### Vérifier qu'un utilisateur a bien accès

```sql
SELECT
  p.email,
  c.name as client_name,
  ucp.permission_level,
  a.name as agents_accessibles
FROM user_client_permissions ucp
JOIN profiles p ON ucp.user_id = p.id
JOIN clients c ON ucp.client_id = c.id
LEFT JOIN agents a ON c.id = a.client_id
WHERE p.email = 'email-a-verifier@example.com'
ORDER BY c.name, a.name;
```

### Vérifier combien d'utilisateurs ont accès à un client

```sql
SELECT
  c.name as client_name,
  COUNT(DISTINCT ucp.user_id) as nombre_utilisateurs,
  STRING_AGG(p.email, ', ' ORDER BY p.email) as utilisateurs
FROM clients c
LEFT JOIN user_client_permissions ucp ON c.id = ucp.client_id
LEFT JOIN profiles p ON ucp.user_id = p.id
GROUP BY c.name
ORDER BY c.name;
```

## Sécurité

- Les permissions sont gérées au niveau base de données via RLS (Row Level Security)
- Un utilisateur ne peut voir que les clients auxquels il a accès
- Les agents sont automatiquement filtrés selon les clients accessibles
- Les appels sont également filtrés selon les permissions

## Notes

- Si vous supprimez un client, ses permissions sont automatiquement supprimées (CASCADE)
- Si vous supprimez un utilisateur de `auth.users`, son profil et ses permissions sont automatiquement supprimés
- Les permissions peuvent être modifiées à chaud, l'utilisateur verra les changements à sa prochaine requête
