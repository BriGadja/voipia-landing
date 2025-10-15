# Configuration Supabase pour l'authentification

## URLs de redirection à configurer

Pour que le système d'authentification fonctionne correctement, vous devez configurer les URLs suivantes dans Supabase Dashboard :

### 1. Accéder à la configuration

1. Allez sur [Supabase Dashboard](https://supabase.com/dashboard)
2. Sélectionnez votre projet
3. Allez dans **Authentication** → **URL Configuration**

### 2. Configurer les URLs

#### Site URL
```
https://voipia.fr
```
OU pour le développement local :
```
http://localhost:3000
```

#### Redirect URLs (Ajouter toutes ces URLs)

**Pour la production :**
```
https://voipia.fr/auth/confirm
https://voipia.fr/auth/callback
https://voipia.fr/auth/update-password
https://voipia.fr/dashboard
```

**Pour le développement local :**
```
http://localhost:3000/auth/confirm
http://localhost:3000/auth/callback
http://localhost:3000/auth/update-password
http://localhost:3000/dashboard
```

### 3. Configurer les templates d'emails

#### Email d'invitation (Invite User)

1. Allez dans **Authentication** → **Email Templates** → **Invite user**
2. Modifiez le template pour utiliser la bonne URL :

```html
<h2>Vous avez été invité</h2>
<p>Vous avez été invité à rejoindre le dashboard Voipia.</p>
<p>Cliquez sur le lien ci-dessous pour définir votre mot de passe :</p>
<p><a href="{{ .ConfirmationURL }}">Définir mon mot de passe</a></p>
```

**IMPORTANT** : Dans les paramètres du template, assurez-vous que l'URL de confirmation pointe vers :
- **Production** : `https://voipia.fr/auth/confirm`
- **Développement** : `http://localhost:3000/auth/confirm`

#### Email de réinitialisation de mot de passe

1. Allez dans **Authentication** → **Email Templates** → **Reset Password**
2. Vérifiez que le template utilise `{{ .ConfirmationURL }}`

### 4. Créer un utilisateur

1. Allez dans **Authentication** → **Users**
2. Cliquez sur **"Add user"** → **"Create new user"**
3. **Email** : Entrez l'email de l'utilisateur
4. **Cochez "Send email invitation"** (recommandé)
5. **OU** : Cochez "Auto Confirm User" et définissez un mot de passe temporaire

### 5. Workflow attendu

#### Option A : Avec email d'invitation (Recommandé)
1. Vous créez l'utilisateur dans Supabase avec "Send email invitation"
2. L'utilisateur reçoit un email avec un lien
3. Il clique sur le lien → redirigé vers `/auth/confirm`
4. `/auth/confirm` extrait le token et redirige vers `/auth/update-password`
5. L'utilisateur définit son mot de passe
6. Il est automatiquement connecté et redirigé vers le dashboard

#### Option B : Sans email d'invitation
1. Vous créez l'utilisateur avec "Auto Confirm User" et un mot de passe temporaire
2. Vous communiquez manuellement l'email et le mot de passe à l'utilisateur
3. L'utilisateur se connecte avec ces identifiants
4. (Optionnel) Il peut changer son mot de passe dans son profil

### 6. Réinitialisation de mot de passe

1. L'utilisateur va sur `/login`
2. Il clique sur "Mot de passe oublié ?"
3. Il entre son email sur `/auth/reset-password`
4. Il reçoit un email avec un lien
5. Il clique sur le lien → redirigé vers `/auth/confirm`
6. `/auth/confirm` extrait le token et redirige vers `/auth/update-password`
7. L'utilisateur définit son nouveau mot de passe
8. Il est automatiquement connecté et redirigé vers le dashboard

## Dépannage

### Problème : L'utilisateur arrive sur la landing page au lieu de la page de mot de passe

**Solution** : Vérifiez que :
1. Les Redirect URLs sont correctement configurées dans Supabase
2. Le Site URL correspond à votre domaine
3. Les emails utilisent `{{ .ConfirmationURL }}` qui pointe vers `/auth/confirm`

### Problème : L'email d'invitation n'est pas reçu

**Solutions** :
1. Vérifiez les spams
2. Dans Supabase Dashboard → Authentication → Logs, vérifiez si l'email a été envoyé
3. Pour le développement, utilisez Inbucket (si configuré dans Supabase)

### Problème : "Email link is invalid or has expired"

**Solutions** :
1. Le lien d'invitation expire après 24h par défaut
2. Renvoyez une nouvelle invitation depuis Supabase Dashboard
3. L'utilisateur peut aussi utiliser "Mot de passe oublié ?" pour obtenir un nouveau lien

## Sécurité

- Les tokens d'accès expirent après 1 heure par défaut
- Les refresh tokens permettent de maintenir la session
- Les liens d'invitation expirent après 24h
- Les mots de passe doivent contenir au moins 8 caractères
- Toutes les communications utilisent HTTPS en production
