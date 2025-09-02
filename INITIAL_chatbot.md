# INITIAL.md - Voipia Embedded Chatbot Widget

## FEATURE:

Je veux créer un chatbot embedded (widget) pour le site Voipia qui s'intègre de manière native et professionnelle. Le chatbot doit avoir les caractéristiques suivantes :

### Interface Utilisateur
- **Widget Position** : Bouton fixe en bas à droite de l'écran (position classique chat widget)
- **État Initial** : Bouton minimaliste avec icône de chat qui pulse légèrement pour attirer l'attention
- **Ouverture** : Animation fluide révélant une fenêtre de chat moderne et responsive 
- **Design** : Cohérent avec l'identité visuelle Voipia (dark theme, gradients purple/violet)
- **Responsive** : Adaptation parfaite mobile/desktop avec gestion des différentes tailles d'écran
- **Animations** : Transitions fluides, effets de typing, indicateurs de chargement élégants

### Fonctionnalités Techniques
- **Webhook Integration** : Envoi des messages utilisateur vers `https://n8n.voipia.fr/webhook/chatbot-iapreneurs`
- **Réponse Asynchrone** : Gestion des réponses via le système "Respond to Webhook" de n8n
- **Format de Communication** : JSON structuré pour optimiser le traitement par n8n
- **Gestion d'Erreurs** : Fallbacks élégants en cas de timeout ou d'erreur réseau
- **Session Management** : Conservation de l'historique de conversation pendant la session
- **Loading States** : Indicateurs visuels pendant les appels API

### Architecture
- **Embed Script** : Script JavaScript autonome et léger, facilement intégrable
- **No Dependencies** : Aucune dépendance externe (pas de jQuery, React, etc.)
- **Vanilla JS** : Code JavaScript pur pour performance maximale et compatibilité
- **CSS Encapsulé** : Styles isolés pour éviter les conflits avec le site existant
- **Lazy Loading** : Chargement asynchrone pour ne pas impacter les performances du site

### Données Échangées
```json
// Envoi vers n8n
{
  "message": "text_utilisateur", 
  "sessionId": "uuid_unique",
  "timestamp": "2025-01-XX...",
  "metadata": {
    "userAgent": "...",
    "referrer": "...",
    "chatId": "..."
  }
}

// Réponse attendue de n8n
{
  "response": "texte_réponse_agent",
  "type": "text|typing|error",
  "metadata": {
    "agent": "chatbot-iapreneurs",
    "confidence": 0.95
  }
}
```

## EXAMPLES:

Dans le dossier `examples/` :
- `chatbot-widget-modern.js` - Exemple d'implémentation de widget chat moderne avec animations
- `n8n-webhook-integration.js` - Pattern d'intégration avec webhooks n8n et gestion des réponses asynchrones
- `embed-script-pattern.js` - Template de script d'intégration autonome sans dépendances
- `voipia-design-system.css` - Styles et variables CSS cohérents avec l'identité Voipia
- `responsive-chat-ui.css` - Patterns CSS pour interface chat responsive et accessible
- `loading-animations.css` - Collection d'animations de chargement élégantes
- `error-handling-patterns.js` - Gestion robuste des erreurs et fallbacks UX

## DOCUMENTATION:

### n8n Documentation (OBLIGATOIRE - recherche internet requise)
- Documentation officielle n8n Webhook node : https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- Documentation Respond to Webhook node : https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.respondtowebhook/
- n8n Community discussions sur webhook responses : https://community.n8n.io/

### Chatbot Widget Best Practices (recherche internet requise)
- Embedded chat widget modern patterns 2025
- JavaScript widget development best practices
- Chat UI/UX design principles
- Webhook integration security practices

### Technical Standards
- Web Accessibility Guidelines (WCAG) pour interfaces conversationnelles
- Performance budgets pour widgets tiers
- Cross-browser compatibility standards
- Mobile-first responsive design patterns

## OTHER CONSIDERATIONS:

### Points Critiques n8n (de l'expertise)
- **TOUJOURS** configurer le Webhook node avec "Respond using 'Respond to Webhook' node" et PAS "When Last Node Finishes"
- **OBLIGATOIRE** : Ajouter un node "Respond to Webhook" à la fin du workflow n8n
- **Attention** : Les webhooks n8n ont un timeout de 100 secondes en cloud, prévoir des réponses rapides
- **Format Response** : Utiliser JSON structuré dans le "Respond to Webhook" node pour éviter l'iframe wrapper automatique de n8n 1.103+

### Pièges Techniques Courants
- **Script Loading** : Éviter le blocking du DOM lors du chargement du widget
- **CSS Conflicts** : Utiliser des préfixes CSS spécifiques (ex: `.voipia-chatbot-*`)
- **Memory Leaks** : Proper cleanup des event listeners et timers
- **Z-index Wars** : Gestion soigneuse des couches d'affichage (z-index: 9999+)
- **CORS Issues** : Configuration correcte pour les appels cross-origin vers n8n

### UX Considerations
- **Accessibilité** : Support clavier complet, lecteurs d'écran, contraste élevé
- **Offline Handling** : Message explicite si pas de connexion réseau
- **Progressive Enhancement** : Le site doit fonctionner même si le chatbot ne charge pas
- **Privacy** : Indication claire sur l'usage des données conversationnelles
- **Mobile UX** : Adaptation de la taille sur mobile (plein écran ou modal)

### Performance Requirements
- **Bundle Size** : < 50KB compressed pour le script embed
- **First Paint** : Widget visible en < 1 seconde
- **Interaction Ready** : Prêt à recevoir input en < 2 secondes
- **API Response Time** : Feedback utilisateur si réponse > 3 secondes

### Security
- **Input Sanitization** : Nettoyage des inputs utilisateur avant envoi à n8n
- **XSS Prevention** : Échappement correct des réponses dans l'interface
- **Rate Limiting** : Prévention du spam côté client
- **HTTPS Only** : Communications chiffrées obligatoires

### Integration Notes
- Le widget doit pouvoir être ajouté au site Voipia avec une simple ligne de script
- Doit coexister harmonieusement avec les autres éléments du site (agents vocaux, etc.)
- Configuration possible via attributs HTML ou paramètres JavaScript
- Compatible avec le système de tracking existant (si applicable)