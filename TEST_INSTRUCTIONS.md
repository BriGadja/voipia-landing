# Instructions de test pour les modifications Voipia

## Démarrage rapide
```bash
# 1. Arrêter tous les serveurs existants (Windows)
taskkill /F /IM node.exe

# 2. Démarrer le serveur de développement
npm run dev

# 3. Ouvrir dans le navigateur
# http://localhost:3000
```

## Points de vérification

### ✅ 1. Bouton "Essayer gratuitement" (Navigation)
- **Où** : Barre de navigation en haut
- **Action** : Cliquer sur le bouton
- **Résultat attendu** : Ouvre https://forms.fillout.com/t/nU9QEqNRRRus dans un nouvel onglet

### ✅ 2. Section Agents sans démos
- **Où** : Section "Rencontrez vos nouveaux agents vocaux"
- **Vérifier** : 
  - Pas de boutons "Écouter la démo"
  - Pas de boutons audio
  - Seulement les informations des agents

### ✅ 3. Modal "Je veux une démo"
- **Où** : Bouton dans la section Hero (première section)
- **Tests à effectuer** :

#### Ouverture et affichage
1. Cliquer sur "Je veux une démo"
2. Vérifier que le modal est centré
3. Vérifier que tous les champs sont visibles

#### Test sur petit écran
1. Réduire la fenêtre du navigateur
2. Vérifier que le modal reste centré
3. Vérifier qu'on peut scroller pour voir tous les champs et boutons

#### Test du formulaire
1. Remplir les champs :
   - Nom complet : Test User
   - Email : test@example.com
   - Téléphone : 0123456789
   - Entreprise : Test Company
   - Message : Test message
2. Cliquer sur "Envoyer"
3. Note : En local, une erreur CORS est normale

#### Test de fermeture
- Cliquer sur le X → doit fermer
- Cliquer sur "Annuler" → doit fermer
- Cliquer en dehors du modal → doit fermer
- Appuyer sur Échap → doit fermer

## Résolution de problèmes

### Si le serveur ne démarre pas sur le port 3000
```bash
# Vérifier quel processus utilise le port
netstat -ano | findstr :3000

# Le serveur démarrera automatiquement sur 3001, 3002, etc.
```

### Si les changements ne s'affichent pas
1. Vider le cache du navigateur (Ctrl+F5)
2. Redémarrer le serveur de développement
3. Vérifier la console pour les erreurs

## Validation finale
- [ ] Bouton "Essayer gratuitement" → Formulaire Fillout ✓
- [ ] Pas de démos audio dans la section Agents ✓
- [ ] Modal centré et scrollable ✓
- [ ] Formulaire envoie vers le webhook ✓
- [ ] Fermeture du modal fonctionne ✓