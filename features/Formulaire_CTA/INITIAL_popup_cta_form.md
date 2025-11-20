# INITIAL - Pop-up Formulaire CTA "Tester nos Agents"

## 📋 Contexte & Objectifs Business

### Problème Actuel
Les boutons CTA "TESTER NOS AGENTS" présents sur le site Voipia ne convertissent pas efficacement :
- Certains pointent vers `/#contact` (ancre qui n'existe pas)
- D'autres n'ont aucune action définie (boutons "morts")
- Friction importante : l'utilisateur doit chercher comment contacter Voipia
- Pas de capture immédiate des leads qualifiés

### Solution Proposée
Implémenter un **système de pop-up formulaire** qui :
- S'ouvre immédiatement au clic sur les CTAs stratégiques
- Capture les informations du prospect (7 champs)
- Déclenche automatiquement un **appel de démonstration dans les 30 secondes**
- Réduit drastiquement la friction utilisateur
- Envoie les données à n8n pour orchestration automatique

### Objectifs Business
- **+50% de conversion** sur les CTAs ciblés
- **Réduction du temps de réponse** : de 24h à 30 secondes
- **Qualification automatique** des leads via le formulaire
- **Amélioration de l'expérience utilisateur** : démo immédiate
- **Tracking précis** : mesure des conversions par CTA

### KPIs de Succès
- Taux de soumission formulaire > 30% (des ouvertures popup)
- Taux de complétion appel démo > 70%
- Taux de prise de RDV post-démo > 40%
- Temps moyen de soumission < 2 minutes

---

## 🎯 Spécifications Fonctionnelles

### Contenu du Popup

#### Titre Principal
```
🎙️ Testez votre futur Agent Vocal IA
```

#### Texte Explicatif (Introduction)
```
Testez notre agent vocal intelligent, capable de rappeler vos leads entrants,
de les qualifier et de prendre des rendez-vous à votre place, 7j/7, en toute autonomie.
```

#### Instructions Utilisateur
```
Laissez vos coordonnées ci-dessous :

👉 Notre agent vous appellera dans les 30 prochaines secondes pour une
   démonstration automatique.

👉 Vous pourrez ensuite réserver un créneau avec Rémi (Co-Fondateur VoIPIA)
   pour parler de son implémentation dans votre organisation.
```

### Formulaire - 7 Champs Requis

#### 1. Prénom *
- **Type** : `text`
- **Placeholder** : `"Jean"`
- **Validation** : Required, minLength: 2, maxLength: 50
- **Label** : `"Prénom :"`
- **Icône** : Aucune

#### 2. Nom *
- **Type** : `text`
- **Placeholder** : `"Michel"`
- **Validation** : Required, minLength: 2, maxLength: 50
- **Label** : `"Nom :"`
- **Icône** : Aucune

#### 3. Nom de votre entreprise *
- **Type** : `text`
- **Placeholder** : `"Google"`
- **Validation** : Required, minLength: 2, maxLength: 100
- **Label** : `"Nom de votre entreprise :"`
- **Icône** : `<Building className="w-4 h-4" />` (Lucide)

#### 4. Site Web de l'entreprise *
- **Type** : `url`
- **Placeholder** : `"https://votresite.com"`
- **Validation** : Required, pattern: `^https?:\/\/.+\..+$`
- **Label** : `"Site Web de l'entreprise :"`
- **Icône** : `<Globe className="w-4 h-4" />` (Lucide)
- **Helper text** : `"URL complète (https://...)"`

#### 5. Secteur d'activité *
- **Type** : `select` (dropdown)
- **Placeholder** : `"Sélectionnez votre secteur"`
- **Options** :
  ```typescript
  const industries = [
    { value: "", label: "Sélectionnez votre secteur" }, // disabled
    { value: "immobilier", label: "Immobilier" },
    { value: "finance", label: "Finance/Banque" },
    { value: "ecommerce", label: "E-commerce" },
    { value: "services-b2b", label: "Services B2B" },
    { value: "sante", label: "Santé" },
    { value: "technologie", label: "Technologie" },
    { value: "education", label: "Éducation" },
    { value: "automobile", label: "Automobile" },
    { value: "autre", label: "Autre" }
  ];
  ```
- **Validation** : Required, valeur non-vide
- **Label** : `"Secteur d'activité :"`
- **Icône** : `<Briefcase className="w-4 h-4" />` (Lucide)

#### 6. Email professionnel *
- **Type** : `email`
- **Placeholder** : `"jean.michel@google.com"`
- **Validation** : Required, type="email"
- **Label** : `"Email professionnel :"`
- **Icône** : `<Mail className="w-4 h-4" />` (Lucide)
- **Helper text** : `"Pour recevoir un récap de la démo et les infos utiles par email"`

#### 7. Numéro de téléphone *
- **Type** : `tel` avec country selector
- **Placeholder** : `"+33 6 66 62 82 99"`
- **Validation** : Required, format E.164
- **Label** : `"Numéro de téléphone :"`
- **Icône** : `<Phone className="w-4 h-4" />` (Lucide)
- **Helper text** : `"Pour recevoir l'appel de notre agent"`
- **Pays par défaut** : France (🇫🇷 +33)

### Bouton de Soumission
- **Texte** : `"Lancer la démonstration ✨"`
- **Variantes** :
  - Normal : `"Lancer la démonstration ✨"`
  - Loading : `"Envoi en cours..."` + spinner
  - Disabled pendant soumission
- **Style** : Gradient violet-purple (cohérent avec charte)
- **Taille** : Large, full width

### Comportements

#### Ouverture du Popup
- Clic sur l'un des 4 CTAs désignés
- Animation : Fade in + scale (0.9 → 1)
- Backdrop blur + dark overlay
- Body scroll locked

#### Fermeture du Popup
- Clic sur backdrop
- Touche Escape
- Clic sur bouton close (X) en haut à droite
- Automatique après succès (+ toast)
- Animation : Fade out + scale (1 → 0.9)

#### Validation en Temps Réel
- Validation HTML5 native (required, type, pattern)
- Focus border coloré (violet/purple)
- Erreur affichée sous le champ si invalide
- Bouton submit désactivé si formulaire incomplet

#### Soumission
1. Validation finale de tous les champs
2. Désactivation du bouton + spinner
3. Envoi POST au webhook n8n
4. Si succès :
   - Fermeture du popup (animation)
   - Affichage toast succès : "Vous allez recevoir un appel dans 30 secondes ! 🎙️"
   - Reset du formulaire
5. Si erreur :
   - Popup reste ouvert
   - Message d'erreur en rouge en haut du formulaire
   - Réactivation du bouton
   - Suggestion : "Une erreur est survenue. Contactez-nous à contact@voipia.fr"

---

## 🎨 Design System & UI/UX

### Structure Visuelle (Référence : capture d'écran fournie)

```
┌─────────────────────────────────────────────────┐
│  [X]  🎙️ Testez votre futur Agent Vocal IA     │
│                                                  │
│  Testez notre agent vocal intelligent...        │
│                                                  │
│  Laissez vos coordonnées ci-dessous :           │
│  👉 Notre agent vous appellera dans les 30...   │
│  👉 Vous pourrez ensuite réserver...            │
│                                                  │
│  ┌─────────────┐  ┌─────────────┐              │
│  │ Prénom : *   │  │ Nom : *      │              │
│  │ [Jean]       │  │ [Michel]     │              │
│  └─────────────┘  └─────────────┘              │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🏢 Nom de votre entreprise : *           │  │
│  │ [Google]                                 │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🌐 Site Web de l'entreprise : *          │  │
│  │ [https://votresite.com]                  │  │
│  │ URL complète (https://...)               │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 💼 Secteur d'activité : *                │  │
│  │ [Sélectionnez votre secteur ▼]          │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ ✉️  Email professionnel : *               │  │
│  │ [jean.michel@google.com]                 │  │
│  │ Pour recevoir un récap...                │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 📞 Numéro de téléphone : *               │  │
│  │ [🇫🇷 ▼] [+33 6 66 62 82 99]             │  │
│  │ Pour recevoir l'appel...                 │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Lancer la démonstration ✨               │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Palette de Couleurs (Cohérence Charte Voipia)

#### Fond Modal
```css
background: rgba(17, 24, 39, 0.95); /* bg-gray-900/95 */
backdrop-filter: blur(24px);
border: 1px solid rgba(255, 255, 255, 0.1);
border-radius: 1rem; /* rounded-2xl */
box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
```

#### Backdrop
```css
background: rgba(0, 0, 0, 0.8); /* bg-black/80 */
backdrop-filter: blur(8px); /* backdrop-blur-sm */
```

#### Inputs Dark
```css
/* État normal */
background: rgba(0, 0, 0, 0.3); /* bg-black/30 */
border: 1px solid rgba(255, 255, 255, 0.1);
color: white;
border-radius: 0.5rem; /* rounded-lg */

/* Focus state */
border-color: #8B5CF6; /* border-purple-500 */
outline: none;
box-shadow: 0 0 0 2px rgba(139, 92, 246, 0.2);

/* Placeholder */
color: rgba(255, 255, 255, 0.4); /* text-white/40 */
```

#### Select Dropdown
```css
/* Même style que inputs + icône chevron */
appearance: none;
background-image: url("data:image/svg+xml...");
background-position: right 1rem center;
background-repeat: no-repeat;
```

#### Bouton Submit
```css
background: linear-gradient(to right, #7C3AED, #9333EA); /* violet-600 to purple-600 */
color: white;
padding: 0.75rem 1.5rem;
border-radius: 0.75rem; /* rounded-xl */
font-weight: 600;
transition: all 0.3s;

/* Hover */
transform: scale(1.02);
box-shadow: 0 10px 30px rgba(139, 92, 246, 0.4);

/* Disabled/Loading */
opacity: 0.6;
cursor: not-allowed;
```

#### Labels & Helper Text
```css
/* Label */
color: rgba(255, 255, 255, 0.9); /* text-white/90 */
font-size: 0.875rem; /* text-sm */
font-weight: 500;
margin-bottom: 0.5rem;

/* Helper text */
color: rgba(255, 255, 255, 0.5); /* text-white/50 */
font-size: 0.75rem; /* text-xs */
margin-top: 0.25rem;
font-style: italic;
```

#### Astérisque Requis
```css
color: #EF4444; /* text-red-500 */
margin-left: 0.25rem;
```

### Animations Framer Motion

#### Ouverture Modal
```typescript
<motion.div
  initial={{ opacity: 0, scale: 0.9, y: 20 }}
  animate={{ opacity: 1, scale: 1, y: 0 }}
  exit={{ opacity: 0, scale: 0.9, y: 20 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
>
```

#### Backdrop
```typescript
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  exit={{ opacity: 0 }}
  transition={{ duration: 0.2 }}
>
```

#### Toast Succès (optionnel)
```typescript
<motion.div
  initial={{ opacity: 0, y: 50, scale: 0.3 }}
  animate={{ opacity: 1, y: 0, scale: 1 }}
  exit={{ opacity: 0, scale: 0.5, transition: { duration: 0.2 } }}
  transition={{ type: "spring", damping: 20, stiffness: 300 }}
>
```

### Responsive Design

#### Mobile (< 640px)
- Modal prend 95% de la largeur
- Padding réduit : `p-4`
- Champs Prénom/Nom empilés verticalement
- Taille texte réduite : `text-xl` pour titre

#### Tablet (640px - 1024px)
- Modal : `max-w-lg` (32rem)
- Champs Prénom/Nom côte à côte
- Padding normal : `p-6`

#### Desktop (> 1024px)
- Modal : `max-w-2xl` (42rem)
- Padding large : `p-8`
- Espacement généreux entre champs

### Accessibilité

#### Focus Management
- Focus trap : focus reste dans le modal
- Ordre logique : top → bottom
- Focus visible : outline violet épais

#### ARIA Labels
```html
<div role="dialog" aria-modal="true" aria-labelledby="popup-title">
  <h2 id="popup-title">Testez votre futur Agent Vocal IA</h2>
  ...
  <input aria-required="true" aria-label="Prénom" />
</div>
```

#### Keyboard Navigation
- **Tab** : navigation entre champs
- **Escape** : ferme le modal
- **Enter** : soumission si tous champs valides

---

## 🏗️ Architecture Technique

### Structure de Fichiers

```
voipia-landing/
├── components/
│   └── ui/
│       ├── CTAPopupForm.tsx          ← Nouveau composant modal
│       └── SuccessToast.tsx          ← Toast de succès (optionnel)
├── lib/
│   └── hooks/
│       └── useCTAPopup.ts            ← Hook global state
└── Formulaire_CTA/
    ├── INITIAL_popup_cta_form.md     ← Ce fichier
    ├── contenu_form.txt              ← Contenu texte
    └── 2025-11-04_07h53_27.png       ← Capture d'écran référence
```

### Composant Principal : CTAPopupForm.tsx

#### Props Interface
```typescript
interface CTAPopupFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}
```

#### State Management
```typescript
interface FormData {
  firstName: string;
  lastName: string;
  company: string;
  website: string;
  industry: string;
  email: string;
  phone: string;
}

const [formData, setFormData] = useState<FormData>({
  firstName: '',
  lastName: '',
  company: '',
  website: '',
  industry: '',
  email: '',
  phone: ''
});

const [isSubmitting, setIsSubmitting] = useState(false);
const [error, setError] = useState<string | null>(null);
```

#### Validation Patterns
```typescript
const URL_PATTERN = /^https?:\/\/.+\..+$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const validateForm = (): boolean => {
  // Vérifier tous les champs requis
  if (!formData.firstName.trim()) return false;
  if (!formData.lastName.trim()) return false;
  if (!formData.company.trim()) return false;
  if (!URL_PATTERN.test(formData.website)) return false;
  if (!formData.industry) return false;
  if (!EMAIL_PATTERN.test(formData.email)) return false;
  if (!formData.phone.trim()) return false;

  return true;
};
```

#### Soumission Webhook
```typescript
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();

  if (!validateForm()) {
    setError('Veuillez remplir tous les champs correctement.');
    return;
  }

  setIsSubmitting(true);
  setError(null);

  try {
    const payload = {
      firstName: formData.firstName,
      lastName: formData.lastName,
      company: formData.company,
      website: formData.website,
      industry: formData.industry,
      email: formData.email,
      phone: formData.phone,
      source: 'landing_cta',
      timestamp: new Date().toISOString()
    };

    const response = await fetch('https://n8n.voipia.fr/webhook/voipia_louis_from_site', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error('Erreur lors de l\'envoi');
    }

    // Succès
    onClose(); // Fermer le modal
    onSuccess?.(); // Callback optionnel (afficher toast)

    // Reset formulaire
    setFormData({
      firstName: '',
      lastName: '',
      company: '',
      website: '',
      industry: '',
      email: '',
      phone: ''
    });

  } catch (err) {
    console.error('Erreur soumission:', err);
    setError('Une erreur est survenue. Veuillez réessayer ou nous contacter à contact@voipia.fr');
  } finally {
    setIsSubmitting(false);
  }
};
```

#### Structure JSX (Squelette)
```tsx
<AnimatePresence>
  {isOpen && (
    <>
      {/* Backdrop */}
      <motion.div
        className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50"
        onClick={onClose}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      />

      {/* Modal Container */}
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <motion.div
          className="bg-gray-900/95 backdrop-blur-xl rounded-2xl border border-white/10
                     shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
          onClick={(e) => e.stopPropagation()}
          initial={{ opacity: 0, scale: 0.9, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.9, y: 20 }}
        >
          {/* Header avec bouton close */}
          <div className="sticky top-0 bg-gray-900/95 backdrop-blur-xl p-6 border-b border-white/10 flex justify-between items-start">
            <h2 className="text-2xl md:text-3xl font-bold text-white">
              🎙️ Testez votre futur Agent Vocal IA
            </h2>
            <button onClick={onClose} className="text-white/60 hover:text-white">
              <X className="w-6 h-6" />
            </button>
          </div>

          {/* Contenu du formulaire */}
          <form onSubmit={handleSubmit} className="p-6 space-y-6">
            {/* Texte explicatif */}
            <div className="text-white/80 space-y-4">
              <p>Testez notre agent vocal intelligent...</p>
              <p>👉 Notre agent vous appellera dans les 30 prochaines secondes...</p>
              <p>👉 Vous pourrez ensuite réserver un créneau avec Rémi...</p>
            </div>

            {/* Message d'erreur */}
            {error && (
              <div className="bg-red-500/10 border border-red-500/50 text-red-400 p-4 rounded-lg">
                {error}
              </div>
            )}

            {/* Champs du formulaire */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Prénom */}
              <FormField label="Prénom" required>
                <input type="text" ... />
              </FormField>

              {/* Nom */}
              <FormField label="Nom" required>
                <input type="text" ... />
              </FormField>
            </div>

            {/* Entreprise */}
            <FormField label="Nom de votre entreprise" icon={<Building />} required>
              <input type="text" ... />
            </FormField>

            {/* Site Web */}
            <FormField label="Site Web de l'entreprise" icon={<Globe />} required helperText="URL complète (https://...)">
              <input type="url" pattern="^https?:\/\/.+\..+$" ... />
            </FormField>

            {/* Secteur */}
            <FormField label="Secteur d'activité" icon={<Briefcase />} required>
              <select ...>
                <option value="">Sélectionnez votre secteur</option>
                <option value="immobilier">Immobilier</option>
                ...
              </select>
            </FormField>

            {/* Email */}
            <FormField label="Email professionnel" icon={<Mail />} required helperText="Pour recevoir un récap...">
              <input type="email" ... />
            </FormField>

            {/* Téléphone */}
            <FormField label="Numéro de téléphone" icon={<Phone />} required helperText="Pour recevoir l'appel...">
              <div className="flex gap-2">
                <select className="w-24">
                  <option value="+33">🇫🇷 +33</option>
                  {/* Autres pays */}
                </select>
                <input type="tel" ... />
              </div>
            </FormField>

            {/* Bouton Submit */}
            <button
              type="submit"
              disabled={isSubmitting || !validateForm()}
              className="w-full bg-gradient-to-r from-violet-600 to-purple-600 ..."
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin mr-2" />
                  Envoi en cours...
                </>
              ) : (
                'Lancer la démonstration ✨'
              )}
            </button>
          </form>
        </motion.div>
      </div>
    </>
  )}
</AnimatePresence>
```

### Hook Global : useCTAPopup.ts

```typescript
import { create } from 'zustand';

interface CTAPopupStore {
  isOpen: boolean;
  open: () => void;
  close: () => void;
  toggle: () => void;
}

export const useCTAPopup = create<CTAPopupStore>((set) => ({
  isOpen: false,
  open: () => set({ isOpen: true }),
  close: () => set({ isOpen: false }),
  toggle: () => set((state) => ({ isOpen: !state.isOpen }))
}));
```

**Note** : Alternative sans Zustand (utiliser useState local dans chaque composant parent)

### Toast de Succès (Optionnel)

```typescript
// components/ui/SuccessToast.tsx
interface SuccessToastProps {
  show: boolean;
  message: string;
  onClose: () => void;
}

export const SuccessToast: React.FC<SuccessToastProps> = ({ show, message, onClose }) => {
  useEffect(() => {
    if (show) {
      const timer = setTimeout(onClose, 5000); // Auto-ferme après 5s
      return () => clearTimeout(timer);
    }
  }, [show, onClose]);

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          className="fixed bottom-8 right-8 bg-green-500 text-white px-6 py-4 rounded-xl
                     shadow-2xl flex items-center gap-3 z-[100]"
          initial={{ opacity: 0, y: 50, scale: 0.3 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, scale: 0.5, transition: { duration: 0.2 } }}
        >
          <CheckCircle className="w-6 h-6" />
          <p className="font-medium">{message}</p>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
```

---

## 🔌 Intégration Webhook n8n

### Endpoint
```
URL: https://n8n.voipia.fr/webhook/voipia_louis_from_site
Méthode: POST
Content-Type: application/json
```

### Format Payload

```json
{
  "firstName": "Jean",
  "lastName": "Michel",
  "company": "Google",
  "website": "https://google.com",
  "industry": "technologie",
  "email": "jean.michel@google.com",
  "phone": "+33666628299",
  "source": "landing_cta",
  "timestamp": "2025-01-20T14:30:00.000Z"
}
```

### Champs Expliqués

| Champ | Type | Exemple | Description |
|-------|------|---------|-------------|
| `firstName` | string | "Jean" | Prénom du prospect |
| `lastName` | string | "Michel" | Nom du prospect |
| `company` | string | "Google" | Nom de l'entreprise |
| `website` | string | "https://google.com" | URL du site (validé) |
| `industry` | string | "technologie" | Secteur (valeur dropdown) |
| `email` | string | "jean@google.com" | Email pro (validé) |
| `phone` | string | "+33666628299" | Téléphone E.164 |
| `source` | string | "landing_cta" | Source du lead |
| `timestamp` | string | ISO-8601 | Date/heure soumission |

### Réponses Attendues

#### Succès (200 OK)
```json
{
  "success": true,
  "message": "Lead enregistré avec succès",
  "callScheduled": true,
  "estimatedCallTime": "30s"
}
```

#### Erreur (400/500)
```json
{
  "success": false,
  "error": "Message d'erreur",
  "code": "VALIDATION_ERROR"
}
```

### Error Handling Frontend

```typescript
try {
  const response = await fetch(webhookUrl, options);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || 'Erreur serveur');
  }

  // Succès
  onSuccess();

} catch (error) {
  // Gestion erreur
  if (error.message.includes('network')) {
    setError('Problème de connexion. Vérifiez votre internet.');
  } else {
    setError('Une erreur est survenue. Contactez contact@voipia.fr');
  }
}
```

---

## 📝 Plan d'Implémentation

### Phase 1 : Création Composant CTAPopupForm (2-3h)

#### Tâches
1. ✅ Créer `components/ui/CTAPopupForm.tsx`
2. ✅ Implémenter structure modal avec AnimatePresence
3. ✅ Créer les 7 champs de formulaire
4. ✅ Implémenter validation HTML5 + custom
5. ✅ Ajouter icônes Lucide pour chaque champ
6. ✅ Implémenter country selector pour téléphone
7. ✅ Créer dropdown secteur d'activité
8. ✅ Implémenter logique de soumission webhook
9. ✅ Ajouter états loading/error/success
10. ✅ Tester responsiveness (mobile/tablet/desktop)

#### Critères de Validation Phase 1
- ✅ Modal s'ouvre et se ferme avec animations
- ✅ Tous les champs sont présents et stylisés
- ✅ Validation fonctionne (champs requis)
- ✅ Bouton submit désactivé si formulaire invalide
- ✅ Loading spinner s'affiche pendant soumission
- ✅ Pas d'erreur console
- ✅ Design glassmorphism cohérent

#### Référence de Code
- Template : `components/ui/ContactModal.tsx`
- Styles : Réutiliser classes glassmorphism
- Animations : Copier patterns de ContactModal

---

### Phase 2 : Hook & State Management (30min)

#### Option A : Hook Global (Zustand)
```bash
npm install zustand
```

```typescript
// lib/hooks/useCTAPopup.ts
import { create } from 'zustand';

interface CTAPopupStore {
  isOpen: boolean;
  showSuccessToast: boolean;
  open: () => void;
  close: () => void;
  setSuccessToast: (show: boolean) => void;
}

export const useCTAPopup = create<CTAPopupStore>((set) => ({
  isOpen: false,
  showSuccessToast: false,
  open: () => set({ isOpen: true }),
  close: () => set({ isOpen: false }),
  setSuccessToast: (show) => set({ showSuccessToast: show })
}));
```

#### Option B : Context API (Pas de dépendance)
```typescript
// lib/contexts/CTAPopupContext.tsx
const CTAPopupContext = createContext(null);

export const CTAPopupProvider = ({ children }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);

  return (
    <CTAPopupContext.Provider value={{
      isOpen,
      setIsOpen,
      showSuccessToast,
      setShowSuccessToast
    }}>
      {children}
    </CTAPopupContext.Provider>
  );
};
```

#### Option C : useState Local (Plus Simple)
Pas de state global, chaque composant CTA gère son propre état.

**Recommandation** : Option C (useState local) pour plus de simplicité

#### Tâches
1. ✅ Créer `components/ui/SuccessToast.tsx` (optionnel)
2. ✅ Implémenter animation toast avec Framer Motion
3. ✅ Tester affichage toast après soumission
4. ✅ Auto-fermeture après 5 secondes

---

### Phase 3 : Connexion des 4 CTAs (1h)

#### Fichiers à Modifier

##### 1. `components/shared/Header.tsx` (ligne ~85)

**Avant** :
```tsx
<Button
  href="/#contact"
  size="sm"
  className="bg-gradient-to-r from-violet-600 to-purple-600"
>
  TESTER NOS AGENTS
</Button>
```

**Après** :
```tsx
const [isPopupOpen, setIsPopupOpen] = useState(false);

// Dans le JSX
<>
  <Button
    onClick={() => setIsPopupOpen(true)}
    size="sm"
    className="bg-gradient-to-r from-violet-600 to-purple-600"
  >
    TESTER NOS AGENTS
  </Button>

  <CTAPopupForm
    isOpen={isPopupOpen}
    onClose={() => setIsPopupOpen(false)}
    onSuccess={() => {
      setShowSuccessToast(true);
      setTimeout(() => setShowSuccessToast(false), 5000);
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

##### 2. `components/landing/HeroHome.tsx` (ligne ~60)

**Avant** :
```tsx
<Button size="lg" variant="primary">
  TESTER NOS AGENTS
</Button>
```

**Après** :
```tsx
const [isPopupOpen, setIsPopupOpen] = useState(false);
const [showSuccessToast, setShowSuccessToast] = useState(false);

<>
  <Button
    size="lg"
    variant="primary"
    onClick={() => setIsPopupOpen(true)}
  >
    TESTER NOS AGENTS
  </Button>

  <CTAPopupForm
    isOpen={isPopupOpen}
    onClose={() => setIsPopupOpen(false)}
    onSuccess={() => {
      setShowSuccessToast(true);
      setTimeout(() => setShowSuccessToast(false), 5000);
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

##### 3. `components/landing/CTAFinal.tsx` (ligne ~46)

Pattern identique aux précédents.

##### 4. `components/landing/BundlePricing.tsx` (ligne ~103)

Pattern identique aux précédents.

#### Imports à Ajouter

Dans chaque fichier modifié :
```typescript
import { useState } from 'react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';
```

#### Critères de Validation Phase 3
- ✅ Popup s'ouvre sur click des 4 CTAs
- ✅ Les 3 CTAs PricingCardsHome gardent leur navigation (non modifiés)
- ✅ Toast de succès s'affiche après soumission
- ✅ Pas de régression sur les autres CTAs
- ✅ Build Next.js réussit sans erreur

---

### Phase 4 : Tests & Optimisations (1h)

#### Tests Fonctionnels

##### Test 1 : Ouverture/Fermeture
- [ ] Clic CTA Header → popup ouvre
- [ ] Clic CTA Hero → popup ouvre
- [ ] Clic CTA Final → popup ouvre
- [ ] Clic CTA Bundle → popup ouvre
- [ ] Clic backdrop → popup ferme
- [ ] Touche Escape → popup ferme
- [ ] Clic bouton X → popup ferme
- [ ] Animations smooth (pas de lag)

##### Test 2 : Validation Formulaire
- [ ] Submit avec champs vides → erreur "champ requis"
- [ ] Email invalide (test@test) → erreur HTML5
- [ ] Site web sans https:// → erreur validation
- [ ] Site web avec https:// → validation OK
- [ ] Secteur non sélectionné → erreur
- [ ] Téléphone invalide → erreur
- [ ] Tous champs valides → bouton submit activé

##### Test 3 : Soumission
- [ ] Formulaire valide → soumission réussit
- [ ] Loading spinner s'affiche pendant envoi
- [ ] Bouton désactivé pendant envoi
- [ ] Succès → popup ferme + toast s'affiche
- [ ] Toast affiche bon message
- [ ] Toast disparaît après 5s
- [ ] Webhook reçoit payload correct

##### Test 4 : Gestion Erreurs
- [ ] Webhook down → message d'erreur s'affiche
- [ ] Message contient email de contact
- [ ] Popup reste ouvert sur erreur
- [ ] Bouton réactivé après erreur
- [ ] Possibilité de réessayer

#### Tests Responsive

##### Mobile (375px)
- [ ] Popup prend 95% largeur
- [ ] Texte lisible (pas trop petit)
- [ ] Champs Prénom/Nom empilés
- [ ] Bouton submit full width
- [ ] Scroll vertical si nécessaire
- [ ] Pas de débordement horizontal

##### Tablet (768px)
- [ ] Popup centrée
- [ ] Champs Prénom/Nom côte à côte
- [ ] Lisibilité optimale
- [ ] Espacement confortable

##### Desktop (1920px)
- [ ] Popup max-w-2xl
- [ ] Ne prend pas tout l'écran
- [ ] Bien centrée
- [ ] Espacement généreux

#### Tests Accessibilité

- [ ] Tab navigation fonctionne
- [ ] Focus visible sur tous les champs
- [ ] Focus trap : on ne peut pas sortir du modal
- [ ] Escape ferme le modal
- [ ] Labels ARIA présents
- [ ] role="dialog" sur modal
- [ ] Lecteur d'écran compatible

#### Tests Performance

##### Lighthouse Audit
- [ ] Performance > 90
- [ ] Accessibility > 95
- [ ] Best Practices > 90
- [ ] SEO non impacté

##### Console
- [ ] Aucune erreur JavaScript
- [ ] Aucun warning React
- [ ] Aucune erreur de réseau (hors test webhook down)

#### Tests Cross-Browser

- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari (MacOS/iOS)

---

## 📊 Critères de Validation Globaux

### Validation Fonctionnelle ✅

- [x] **Popup s'ouvre correctement** sur les 4 CTAs désignés
- [x] **Popup NE s'ouvre PAS** sur les 3 CTAs PricingCardsHome (navigation préservée)
- [x] **Formulaire contient 7 champs** tous requis avec validation
- [x] **Dropdown secteur** affiche 9 options
- [x] **Validation URL** refuse formats invalides
- [x] **Validation email** refuse formats invalides
- [x] **Country selector** téléphone fonctionne (France par défaut)
- [x] **Webhook** reçoit payload JSON correct
- [x] **Succès** : popup ferme + toast "Appel dans 30s"
- [x] **Erreur** : message affiché + popup reste ouvert
- [x] **Loading state** : bouton désactivé + spinner pendant soumission
- [x] **Escape/backdrop** ferme le popup

### Validation UI/UX ✅

- [x] **Design glassmorphism** cohérent avec charte Voipia
- [x] **Animations Framer Motion** fluides (fade + scale)
- [x] **Responsive** parfait (mobile/tablet/desktop)
- [x] **Focus states** visibles (border violet)
- [x] **Helper texts** présents (email, téléphone, site web)
- [x] **Icônes Lucide** sur champs appropriés
- [x] **Astérisques rouges** sur champs requis
- [x] **Bouton gradient** violet-purple avec hover effect

### Validation Technique ✅

- [x] **TypeScript** : pas d'erreur de type
- [x] **Build Next.js** réussit (`npm run build`)
- [x] **Lint** réussit (`npm run lint`)
- [x] **Console** : aucune erreur JavaScript
- [x] **Lighthouse Performance** > 90
- [x] **Lighthouse Accessibility** > 95
- [x] **Pas de régression** sur fonctionnalités existantes

### Validation Business ✅

- [x] **Webhook n8n** déclenche appel démo automatique
- [x] **Payload** contient toutes les données nécessaires
- [x] **Source tracking** : champ "source" = "landing_cta"
- [x] **Timestamp** inclus pour analytics
- [x] **Message clair** pour l'utilisateur (appel dans 30s)
- [x] **Fallback contact** si erreur (email contact@voipia.fr)

---

## 📁 Récapitulatif des Fichiers

### Fichiers à CRÉER ✨

```
components/ui/CTAPopupForm.tsx          - Composant modal principal (~300 lignes)
components/ui/SuccessToast.tsx          - Toast de confirmation (~50 lignes)
lib/hooks/useCTAPopup.ts                - Hook global state (optionnel, ~20 lignes)
```

### Fichiers à MODIFIER 🔧

**4 fichiers de CTAs (ajout onClick + state)** :
```
components/shared/Header.tsx            - Ligne ~85 : CTA bandeau
components/landing/HeroHome.tsx         - Ligne ~60 : CTA hero
components/landing/CTAFinal.tsx         - Ligne ~46 : CTA section finale
components/landing/BundlePricing.tsx    - Ligne ~103 : CTA bundle
```

**Modifications par fichier** :
- Import : CTAPopupForm, SuccessToast
- State : useState pour isPopupOpen et showSuccessToast
- onClick : setIsPopupOpen(true) sur bouton
- JSX : Ajout composants CTAPopupForm + SuccessToast

### Fichiers RÉFÉRENCE 📚 (ne pas modifier)

```
components/ui/ContactModal.tsx          - Template structure modal
components/shared/Button/index.tsx      - API du bouton
components/ui/GlassCard.tsx            - Styles glassmorphism
lib/data/agents.ts                     - Données agents (si nécessaire)
tailwind.config.ts                     - Palette de couleurs
app/globals.css                        - Utilities CSS
```

### Fichiers à NE PAS TOUCHER ⛔

```
components/landing/PricingCardsHome.tsx     - Garder navigation /louis, /arthur, /alexandra
components/landing/HeroLouis.tsx            - Navigation vers /louis
components/landing/HeroArthur.tsx           - Navigation vers /arthur
components/landing/HeroAlexandra.tsx        - Navigation vers /alexandra
components/landing/PricingLouis.tsx         - Navigation vers /louis
components/landing/PricingArthur.tsx        - Navigation vers /arthur
components/landing/PricingAlexandra.tsx     - Navigation vers /alexandra
components/landing/CTAFinalLouis.tsx        - Navigation vers /louis
components/landing/CTAFinalArthur.tsx       - Navigation vers /arthur
components/landing/CTAFinalAlexandra.tsx    - Navigation vers /alexandra
```

---

## 🚀 Commandes de Développement

### Démarrage du Serveur Dev
```bash
# Tuer processus sur port 3000 (si nécessaire)
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Démarrer le serveur
npm run dev
```

### Build & Lint
```bash
# Build de production
npm run build

# Lint
npm run lint

# Type check
npx tsc --noEmit
```

### Tests Visuels (MCP Playwright)
```bash
# Naviguer vers la page
mcp__playwright__browser_navigate({ url: "http://localhost:3000" })

# Prendre un snapshot
mcp__playwright__browser_snapshot()

# Tester le popup
mcp__playwright__browser_click({ element: "CTA Header", ref: "..." })
mcp__playwright__browser_snapshot()
```

---

## 📈 Prochaines Étapes

### Étape 1 : Validation de ce INITIAL.md
- [ ] Lire et valider toutes les sections
- [ ] Confirmer les 7 champs de formulaire
- [ ] Valider la liste des secteurs d'activité
- [ ] Confirmer les 4 CTAs à modifier
- [ ] Approuver le design glassmorphism

### Étape 2 : Génération du PRP
```bash
/generate-prp "Pop-up formulaire CTA - Composant CTAPopupForm avec 7 champs, validation, et intégration webhook n8n pour démo automatique"
```

### Étape 3 : Exécution du PRP
```bash
/execute-prp proposition_restructuration_landing/PRPs/popup-cta-form.md
```

### Étape 4 : Tests & Validation
- [ ] Tests fonctionnels (validation, soumission)
- [ ] Tests responsiveness (mobile/tablet/desktop)
- [ ] Tests accessibilité (keyboard, screen reader)
- [ ] Tests performance (Lighthouse)
- [ ] Tests cross-browser

### Étape 5 : Déploiement
- [ ] Commit Git avec message descriptif
- [ ] Push vers branche feature
- [ ] Review code (si applicable)
- [ ] Merge vers main
- [ ] Vérifier en production

---

## 💡 Notes & Recommandations

### Dépendances Recommandées

**Déjà installées** ✅ :
- `framer-motion` - Animations
- `lucide-react` - Icônes
- `clsx` + `tailwind-merge` - Utility classes

**À installer** (optionnelles) :
- `react-phone-number-input` - Country selector professionnel (si besoin)
- `zustand` - State management global (si hook global choisi)

**Recommandation** : Rester avec les dépendances existantes (pas d'install supplémentaire)

### Améliorations Futures (Post-MVP)

1. **Analytics Avancés** :
   - Tracking événements (ouverture popup, champs remplis, soumission)
   - A/B testing différents CTAs
   - Funnel conversion analysis

2. **UX Améliorée** :
   - Autocomplétion entreprise via API
   - Détection automatique du secteur via site web
   - Validation email en temps réel (vérifier domaine)

3. **Personnalisation** :
   - Pré-remplissage si utilisateur connu (cookies)
   - Message personnalisé selon la page d'origine
   - Agent pré-sélectionné selon contexte

4. **Intégrations** :
   - Calendly directement dans le popup (post-soumission)
   - CRM sync automatique (HubSpot, Salesforce)
   - Slack notification pour équipe sales

---

## 📞 Support & Contact

### En Cas de Problème

**Webhook n8n ne répond pas** :
- Vérifier que l'URL est correcte
- Tester avec Postman/curl
- Vérifier les logs n8n

**Erreurs de build** :
- Vérifier les imports TypeScript
- Lancer `npm run lint` pour détecter les erreurs
- Vérifier les peer dependencies

**Problèmes de style** :
- Vérifier que Tailwind compile correctement
- Purge CSS peut supprimer des classes dynamiques
- Utiliser safelist si nécessaire

### Contact Technique
- **Email** : contact@voipia.fr
- **Documentation n8n** : [n8n.voipia.fr/workflows](https://n8n.voipia.fr)

---

## ✅ Checklist Finale

Avant de marquer cette évolution comme terminée :

### Développement
- [ ] CTAPopupForm.tsx créé et fonctionnel
- [ ] SuccessToast.tsx créé (si nécessaire)
- [ ] 4 CTAs modifiés avec onClick handlers
- [ ] Webhook intégré et testé
- [ ] Validation formulaire fonctionne
- [ ] Loading/error states implémentés

### Tests
- [ ] Tests fonctionnels (tous les scénarios)
- [ ] Tests responsive (mobile/tablet/desktop)
- [ ] Tests accessibilité (WCAG 2.1 AA)
- [ ] Tests performance (Lighthouse > 90)
- [ ] Tests cross-browser (Chrome, Firefox, Safari)

### Documentation
- [ ] Code commenté
- [ ] Types TypeScript documentés
- [ ] README mis à jour (si nécessaire)
- [ ] PROGRESS_REFONTE.md mis à jour

### Validation Business
- [ ] Webhook n8n reçoit bien les données
- [ ] Appel démo se déclenche dans les 30s
- [ ] Message de succès clair pour l'utilisateur
- [ ] Tracking analytics en place

### Déploiement
- [ ] Build production réussit
- [ ] Lint sans erreur
- [ ] Commit Git avec message descriptif
- [ ] Push vers repository
- [ ] Vérification en production

---

**Document créé le** : 2025-01-20
**Dernière mise à jour** : 2025-01-20
**Version** : 1.0
**Auteur** : Claude (Anthropic)
**Statut** : ✅ Prêt pour implémentation
