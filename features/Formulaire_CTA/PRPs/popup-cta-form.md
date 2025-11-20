# PRP - Pop-up Formulaire CTA avec Webhook n8n

## 🎯 Purpose & Goal

Implémenter un système de pop-up formulaire de capture de leads avec déclenchement automatique d'un appel de démonstration dans les 30 secondes via webhook n8n.

### Objectifs Business
- **+50% de conversion** sur les CTAs ciblés
- **Réduction friction** : capture immédiate vs recherche de contact
- **Démo instantanée** : appel automatique sous 30 secondes
- **Qualification automatique** : 7 champs structurés

### Scope
- ✅ Créer composant modal CTAPopupForm avec 7 champs
- ✅ Intégrer webhook n8n pour orchestration
- ✅ Modifier 4 CTAs spécifiques pour ouvrir le popup
- ✅ Préserver navigation existante (pages agents)
- ✅ Toast de confirmation post-soumission
- ❌ Pas de tracking analytics avancé (post-MVP)
- ❌ Pas de pré-remplissage utilisateur (post-MVP)

---

## 📚 Context & References

### Required Reading

```yaml
files_to_read:
  - file: C:\Users\pc\Documents\Projets\voipia-landing\Formulaire_CTA\INITIAL_popup_cta_form.md
    why: Spécifications complètes du popup (design, champs, validations, webhook)
    sections: Toutes sections (1140 lignes)

  - file: components/ui/ContactModal.tsx
    why: Template de référence pour structure modal avec Framer Motion
    patterns: AnimatePresence, backdrop, form structure, states

  - file: components/shared/Button/index.tsx
    why: API du composant Button (variants, sizes, onClick)
    usage: Comprendre comment modifier les CTAs existants

  - file: components/shared/Header.tsx
    why: Premier CTA à modifier (ligne ~85)
    modification: Ajouter onClick + state pour ouvrir popup

  - file: components/landing/HeroHome.tsx
    why: Deuxième CTA à modifier (ligne ~60)
    modification: Ajouter onClick + state pour ouvrir popup

  - file: components/landing/CTAFinal.tsx
    why: Troisième CTA à modifier (ligne ~46)
    modification: Ajouter onClick + state pour ouvrir popup

  - file: components/landing/BundlePricing.tsx
    why: Quatrième CTA à modifier (ligne ~103)
    modification: Ajouter onClick + state pour ouvrir popup

  - file: tailwind.config.ts
    why: Palette de couleurs (violet-600, purple-600, glassmorphism)
    usage: Cohérence design system

  - file: lib/utils.ts
    why: Fonction cn() pour classes conditionnelles
    usage: Construction classes Tailwind dynamiques
```

### External Documentation
- Framer Motion AnimatePresence: https://www.framer.com/motion/animate-presence/
- HTML5 Form Validation: https://developer.mozilla.org/en-US/docs/Learn/Forms/Form_validation
- n8n Webhooks: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/

---

## 🏗️ Implementation Blueprint

### Phase 1: Créer CTAPopupForm Component

#### 1.1 Types & Interfaces

**File**: `components/ui/CTAPopupForm.tsx`

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  X,
  Building,
  Globe,
  Briefcase,
  Mail,
  Phone,
  Loader2
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CTAPopupFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

interface FormData {
  firstName: string;
  lastName: string;
  company: string;
  website: string;
  industry: string;
  email: string;
  phone: string;
  countryCode: string;
}

interface FormFieldProps {
  label: string;
  required?: boolean;
  icon?: React.ReactNode;
  helperText?: string;
  children: React.ReactNode;
}
```

#### 1.2 FormField Component (Helper)

```typescript
const FormField: React.FC<FormFieldProps> = ({
  label,
  required,
  icon,
  helperText,
  children
}) => (
  <div className="space-y-2">
    <label className="flex items-center gap-2 text-sm font-medium text-white/90">
      {icon && <span className="text-white/60">{icon}</span>}
      {label}
      {required && <span className="text-red-500">*</span>}
    </label>
    {children}
    {helperText && (
      <p className="text-xs text-white/50 italic">{helperText}</p>
    )}
  </div>
);
```

#### 1.3 Industries Constant

```typescript
const INDUSTRIES = [
  { value: '', label: 'Sélectionnez votre secteur', disabled: true },
  { value: 'immobilier', label: 'Immobilier' },
  { value: 'finance', label: 'Finance/Banque' },
  { value: 'ecommerce', label: 'E-commerce' },
  { value: 'services-b2b', label: 'Services B2B' },
  { value: 'sante', label: 'Santé' },
  { value: 'technologie', label: 'Technologie' },
  { value: 'education', label: 'Éducation' },
  { value: 'automobile', label: 'Automobile' },
  { value: 'autre', label: 'Autre' }
];

const COUNTRY_CODES = [
  { value: '+33', label: '🇫🇷 +33', flag: '🇫🇷' },
  { value: '+1', label: '🇺🇸 +1', flag: '🇺🇸' },
  { value: '+44', label: '🇬🇧 +44', flag: '🇬🇧' },
  { value: '+32', label: '🇧🇪 +32', flag: '🇧🇪' },
  { value: '+41', label: '🇨🇭 +41', flag: '🇨🇭' }
];
```

#### 1.4 Validation Patterns

```typescript
const URL_PATTERN = /^https?:\/\/.+\..+$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const validateForm = (data: FormData): boolean => {
  if (!data.firstName.trim()) return false;
  if (!data.lastName.trim()) return false;
  if (!data.company.trim()) return false;
  if (!URL_PATTERN.test(data.website)) return false;
  if (!data.industry) return false;
  if (!EMAIL_PATTERN.test(data.email)) return false;
  if (!data.phone.trim() || data.phone.length < 6) return false;
  return true;
};
```

#### 1.5 Main Component Logic

```typescript
const CTAPopupForm: React.FC<CTAPopupFormProps> = ({
  isOpen,
  onClose,
  onSuccess
}) => {
  const [formData, setFormData] = useState<FormData>({
    firstName: '',
    lastName: '',
    company: '',
    website: '',
    industry: '',
    email: '',
    phone: '',
    countryCode: '+33'
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Lock body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  // Close on Escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  const handleChange = (field: keyof FormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    setError(null); // Clear error on change
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm(formData)) {
      setError('Veuillez remplir tous les champs correctement.');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const payload = {
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim(),
        company: formData.company.trim(),
        website: formData.website.trim(),
        industry: formData.industry,
        email: formData.email.trim().toLowerCase(),
        phone: `${formData.countryCode}${formData.phone.replace(/\s/g, '')}`,
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

      // Success
      onClose();
      onSuccess?.();

      // Reset form
      setFormData({
        firstName: '',
        lastName: '',
        company: '',
        website: '',
        industry: '',
        email: '',
        phone: '',
        countryCode: '+33'
      });

    } catch (err) {
      console.error('Erreur soumission:', err);
      setError('Une erreur est survenue. Veuillez réessayer ou nous contacter à contact@voipia.fr');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isFormValid = validateForm(formData);

  // Continue with JSX...
```

#### 1.6 JSX Markup

```typescript
  return (
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
            transition={{ duration: 0.2 }}
          />

          {/* Modal Container */}
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              className={cn(
                "bg-gray-900/95 backdrop-blur-xl rounded-2xl",
                "border border-white/10 shadow-2xl",
                "max-w-2xl w-full max-h-[90vh] overflow-y-auto",
                "scrollbar-thin scrollbar-thumb-white/10 scrollbar-track-transparent"
              )}
              onClick={(e) => e.stopPropagation()}
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              transition={{ duration: 0.3, ease: 'easeOut' }}
            >
              {/* Header */}
              <div className="sticky top-0 bg-gray-900/95 backdrop-blur-xl p-6 border-b border-white/10 flex justify-between items-start">
                <h2 className="text-2xl md:text-3xl font-bold text-white">
                  🎙️ Testez votre futur Agent Vocal IA
                </h2>
                <button
                  onClick={onClose}
                  className="text-white/60 hover:text-white transition-colors"
                  aria-label="Fermer"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* Form Content */}
              <form onSubmit={handleSubmit} className="p-6 md:p-8 space-y-6">
                {/* Intro Text */}
                <div className="text-white/80 space-y-3 text-sm md:text-base">
                  <p>
                    Testez notre agent vocal intelligent, capable de rappeler vos leads entrants,
                    de les qualifier et de prendre des rendez-vous à votre place, 7j/7, en toute autonomie.
                  </p>
                  <p className="font-medium">Laissez vos coordonnées ci-dessous :</p>
                  <p className="flex items-start gap-2">
                    <span>👉</span>
                    <span>Notre agent vous appellera dans les 30 prochaines secondes pour une démonstration automatique.</span>
                  </p>
                  <p className="flex items-start gap-2">
                    <span>👉</span>
                    <span>Vous pourrez ensuite réserver un créneau avec Rémi (Co-Fondateur VoIPIA) pour parler de son implémentation dans votre organisation.</span>
                  </p>
                </div>

                {/* Error Message */}
                {error && (
                  <div className="bg-red-500/10 border border-red-500/50 text-red-400 p-4 rounded-lg text-sm">
                    {error}
                  </div>
                )}

                {/* Name Fields - Side by Side on Desktop */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <FormField label="Prénom" required>
                    <input
                      type="text"
                      value={formData.firstName}
                      onChange={(e) => handleChange('firstName', e.target.value)}
                      placeholder="Jean"
                      required
                      minLength={2}
                      maxLength={50}
                      className={cn(
                        "w-full px-4 py-2 bg-black/30 border border-white/10",
                        "rounded-lg text-white placeholder-white/40",
                        "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                        "transition-colors"
                      )}
                    />
                  </FormField>

                  <FormField label="Nom" required>
                    <input
                      type="text"
                      value={formData.lastName}
                      onChange={(e) => handleChange('lastName', e.target.value)}
                      placeholder="Michel"
                      required
                      minLength={2}
                      maxLength={50}
                      className={cn(
                        "w-full px-4 py-2 bg-black/30 border border-white/10",
                        "rounded-lg text-white placeholder-white/40",
                        "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                        "transition-colors"
                      )}
                    />
                  </FormField>
                </div>

                {/* Company */}
                <FormField label="Nom de votre entreprise" icon={<Building className="w-4 h-4" />} required>
                  <input
                    type="text"
                    value={formData.company}
                    onChange={(e) => handleChange('company', e.target.value)}
                    placeholder="Google"
                    required
                    minLength={2}
                    maxLength={100}
                    className={cn(
                      "w-full px-4 py-2 bg-black/30 border border-white/10",
                      "rounded-lg text-white placeholder-white/40",
                      "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                      "transition-colors"
                    )}
                  />
                </FormField>

                {/* Website */}
                <FormField
                  label="Site Web de l'entreprise"
                  icon={<Globe className="w-4 h-4" />}
                  required
                  helperText="URL complète (https://...)"
                >
                  <input
                    type="url"
                    value={formData.website}
                    onChange={(e) => handleChange('website', e.target.value)}
                    placeholder="https://votresite.com"
                    required
                    pattern="^https?:\/\/.+\..+$"
                    className={cn(
                      "w-full px-4 py-2 bg-black/30 border border-white/10",
                      "rounded-lg text-white placeholder-white/40",
                      "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                      "transition-colors"
                    )}
                  />
                </FormField>

                {/* Industry Select */}
                <FormField label="Secteur d'activité" icon={<Briefcase className="w-4 h-4" />} required>
                  <select
                    value={formData.industry}
                    onChange={(e) => handleChange('industry', e.target.value)}
                    required
                    className={cn(
                      "w-full px-4 py-2 bg-black/30 border border-white/10",
                      "rounded-lg text-white",
                      "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                      "transition-colors appearance-none cursor-pointer",
                      "bg-[url('data:image/svg+xml;charset=UTF-8,%3csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2012%2012%22%3e%3cpath%20fill%3D%22%23ffffff66%22%20d%3D%22M10.293%203.293L6%207.586%201.707%203.293A1%201%200%200%200%20.293%204.707l5%205a1%201%200%200%200%201.414%200l5-5a1%201%200%201%200-1.414-1.414z%22%2F%3e%3c%2Fsvg%3e')]",
                      "bg-[length:1rem] bg-[right_1rem_center] bg-no-repeat"
                    )}
                  >
                    {INDUSTRIES.map((ind) => (
                      <option
                        key={ind.value}
                        value={ind.value}
                        disabled={ind.disabled}
                        className="bg-gray-900 text-white"
                      >
                        {ind.label}
                      </option>
                    ))}
                  </select>
                </FormField>

                {/* Email */}
                <FormField
                  label="Email professionnel"
                  icon={<Mail className="w-4 h-4" />}
                  required
                  helperText="Pour recevoir un récap de la démo et les infos utiles par email"
                >
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => handleChange('email', e.target.value)}
                    placeholder="jean.michel@google.com"
                    required
                    className={cn(
                      "w-full px-4 py-2 bg-black/30 border border-white/10",
                      "rounded-lg text-white placeholder-white/40",
                      "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                      "transition-colors"
                    )}
                  />
                </FormField>

                {/* Phone */}
                <FormField
                  label="Numéro de téléphone"
                  icon={<Phone className="w-4 h-4" />}
                  required
                  helperText="Pour recevoir l'appel de notre agent"
                >
                  <div className="flex gap-2">
                    <select
                      value={formData.countryCode}
                      onChange={(e) => handleChange('countryCode', e.target.value)}
                      className={cn(
                        "w-28 px-3 py-2 bg-black/30 border border-white/10",
                        "rounded-lg text-white",
                        "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                        "transition-colors appearance-none cursor-pointer"
                      )}
                    >
                      {COUNTRY_CODES.map((country) => (
                        <option
                          key={country.value}
                          value={country.value}
                          className="bg-gray-900 text-white"
                        >
                          {country.label}
                        </option>
                      ))}
                    </select>
                    <input
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => handleChange('phone', e.target.value)}
                      placeholder="6 66 62 82 99"
                      required
                      minLength={6}
                      className={cn(
                        "flex-1 px-4 py-2 bg-black/30 border border-white/10",
                        "rounded-lg text-white placeholder-white/40",
                        "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                        "transition-colors"
                      )}
                    />
                  </div>
                </FormField>

                {/* Submit Button */}
                <button
                  type="submit"
                  disabled={isSubmitting || !isFormValid}
                  className={cn(
                    "w-full py-3 px-6 rounded-xl font-semibold",
                    "bg-gradient-to-r from-violet-600 to-purple-600",
                    "text-white text-lg",
                    "transition-all duration-300",
                    "flex items-center justify-center gap-2",
                    isFormValid && !isSubmitting && "hover:scale-[1.02] hover:shadow-lg hover:shadow-purple-500/40",
                    (isSubmitting || !isFormValid) && "opacity-60 cursor-not-allowed"
                  )}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
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
  );
};

export default CTAPopupForm;
```

---

### Phase 2: Créer SuccessToast Component

**File**: `components/ui/SuccessToast.tsx`

```typescript
'use client';

import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle, X } from 'lucide-react';

interface SuccessToastProps {
  show: boolean;
  message: string;
  onClose: () => void;
}

const SuccessToast: React.FC<SuccessToastProps> = ({ show, message, onClose }) => {
  useEffect(() => {
    if (show) {
      const timer = setTimeout(onClose, 5000); // Auto-close after 5s
      return () => clearTimeout(timer);
    }
  }, [show, onClose]);

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          className="fixed bottom-8 right-8 bg-green-500 text-white px-6 py-4 rounded-xl shadow-2xl flex items-center gap-3 z-[100] max-w-md"
          initial={{ opacity: 0, y: 50, scale: 0.3 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, scale: 0.5, transition: { duration: 0.2 } }}
          transition={{ type: 'spring', damping: 20, stiffness: 300 }}
        >
          <CheckCircle className="w-6 h-6 flex-shrink-0" />
          <p className="font-medium flex-1">{message}</p>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white transition-colors"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default SuccessToast;
```

---

### Phase 3: Modifier les 4 CTAs

#### 3.1 Header.tsx

**File**: `components/shared/Header.tsx`

```typescript
// Add imports at top
'use client';
import { useState } from 'react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

// Inside component (before return statement)
const [isPopupOpen, setIsPopupOpen] = useState(false);
const [showSuccessToast, setShowSuccessToast] = useState(false);

// Replace existing CTA button (around line 85)
// BEFORE:
<Button
  href="/#contact"
  size="sm"
  className="bg-gradient-to-r from-violet-600 to-purple-600"
>
  TESTER NOS AGENTS
</Button>

// AFTER:
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
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

#### 3.2 HeroHome.tsx

**File**: `components/landing/HeroHome.tsx`

```typescript
// Add imports at top
'use client';
import { useState } from 'react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

// Inside component (before return statement)
const [isPopupOpen, setIsPopupOpen] = useState(false);
const [showSuccessToast, setShowSuccessToast] = useState(false);

// Replace existing CTA button (around line 60)
// BEFORE:
<Button size="lg" variant="primary">
  TESTER NOS AGENTS
</Button>

// AFTER:
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
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

#### 3.3 CTAFinal.tsx

**File**: `components/landing/CTAFinal.tsx`

```typescript
// Add imports at top
'use client';
import { useState } from 'react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

// Inside component (before return statement)
const [isPopupOpen, setIsPopupOpen] = useState(false);
const [showSuccessToast, setShowSuccessToast] = useState(false);

// Replace existing CTA button (around line 46)
// BEFORE:
<Button size="lg" variant="primary">
  TESTER NOS AGENTS
</Button>

// AFTER:
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
      setShowSuccessToast(true)}
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

#### 3.4 BundlePricing.tsx

**File**: `components/landing/BundlePricing.tsx`

```typescript
// Add imports at top
'use client';
import { useState } from 'react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

// Inside component (before return statement)
const [isPopupOpen, setIsPopupOpen] = useState(false);
const [showSuccessToast, setShowSuccessToast] = useState(false);

// Replace existing CTA button (around line 103)
// BEFORE:
<Button size="lg" variant="primary">
  TESTER LE PACK COMPLET
</Button>

// AFTER:
<>
  <Button
    size="lg"
    variant="primary"
    onClick={() => setIsPopupOpen(true)}
  >
    TESTER LE PACK COMPLET
  </Button>

  <CTAPopupForm
    isOpen={isPopupOpen}
    onClose={() => setIsPopupOpen(false)}
    onSuccess={() => {
      setShowSuccessToast(true);
    }}
  />

  <SuccessToast
    show={showSuccessToast}
    message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
    onClose={() => setShowSuccessToast(false)}
  />
</>
```

---

## ✅ Validation Loops

### Loop 1: Development Server & Build

```bash
# Kill any process on port 3000
netstat -ano | findstr :3000
# If found, kill: taskkill /PID <PID> /F

# Start dev server
npm run dev

# Verify no errors in terminal
# Expected: Server running on http://localhost:3000
```

**Expected Outcome**:
- ✅ Server starts without errors
- ✅ No TypeScript compilation errors
- ✅ No missing module errors

---

### Loop 2: Visual Verification (MCP Playwright)

```bash
# Navigate to homepage
mcp__playwright__browser_navigate({ url: "http://localhost:3000" })

# Take initial snapshot
mcp__playwright__browser_snapshot()

# Test Header CTA
mcp__playwright__browser_click({
  element: "TESTER NOS AGENTS button in header",
  ref: "[data-testid='header-cta']" or similar selector
})

# Verify popup opened
mcp__playwright__browser_snapshot()

# Test form filling
mcp__playwright__browser_type({
  element: "Prénom input",
  ref: "input[placeholder='Jean']",
  text: "Test"
})

# Take snapshot of filled form
mcp__playwright__browser_snapshot()

# Test close on backdrop
mcp__playwright__browser_click({
  element: "Modal backdrop",
  ref: ".fixed.inset-0.bg-black"
})

# Verify popup closed
mcp__playwright__browser_snapshot()
```

**Expected Outcome**:
- ✅ Popup opens with smooth animation
- ✅ All 7 fields are visible and styled
- ✅ Closing works (backdrop, X button, Escape)
- ✅ Design matches glassmorphism style

---

### Loop 3: Form Validation Tests

**Test 1: Empty Submit**
```bash
# Open popup, leave fields empty, try submit
# Expected: HTML5 validation errors appear
```

**Test 2: Invalid URL**
```bash
# Enter "google.com" in website field (no https://)
# Expected: Pattern validation error
```

**Test 3: Invalid Email**
```bash
# Enter "test@test" in email field
# Expected: Email validation error
```

**Test 4: Valid Form**
```bash
# Fill all fields correctly
# Expected: Submit button enabled, no errors
```

**Expected Outcome**:
- ✅ Required fields show native validation
- ✅ URL pattern validated correctly
- ✅ Email pattern validated correctly
- ✅ Submit button disabled when invalid

---

### Loop 4: Webhook Integration Test

**Manual Test** (Use browser console or Postman):

```javascript
// Test payload
fetch('https://n8n.voipia.fr/webhook/voipia_louis_from_site', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    firstName: "Test",
    lastName: "User",
    company: "Test Co",
    website: "https://test.com",
    industry: "technologie",
    email: "test@test.com",
    phone: "+33666666666",
    source: "landing_cta",
    timestamp: new Date().toISOString()
  })
})
.then(res => res.json())
.then(console.log)
.catch(console.error);
```

**Expected Outcome**:
- ✅ Webhook returns 200 OK
- ✅ n8n workflow triggered
- ✅ No CORS errors
- ✅ Payload format accepted

---

### Loop 5: Responsive Design Tests

```bash
# Mobile (375px)
mcp__playwright__browser_resize({ width: 375, height: 667 })
mcp__playwright__browser_snapshot()

# Tablet (768px)
mcp__playwright__browser_resize({ width: 768, height: 1024 })
mcp__playwright__browser_snapshot()

# Desktop (1920px)
mcp__playwright__browser_resize({ width: 1920, height: 1080 })
mcp__playwright__browser_snapshot()
```

**Expected Outcome**:
- ✅ Mobile: Fields stacked vertically, 95% width
- ✅ Tablet: Prénom/Nom side-by-side, max-w-lg
- ✅ Desktop: max-w-2xl, generous spacing
- ✅ No horizontal scroll on any size

---

### Loop 6: Lint & Type Check

```bash
# Run lint
npm run lint

# Expected: No errors or warnings

# Run type check
npx tsc --noEmit

# Expected: No TypeScript errors
```

**Expected Outcome**:
- ✅ ESLint passes (0 errors, 0 warnings)
- ✅ TypeScript compiles without errors
- ✅ No unused imports or variables

---

### Loop 7: Production Build

```bash
# Build for production
npm run build

# Expected: Build completes successfully
# Check build output for bundle size
```

**Expected Outcome**:
- ✅ Build succeeds without errors
- ✅ No bundle size warnings
- ✅ Pages generated successfully
- ✅ Static optimization applied where possible

---

### Loop 8: Regression Tests

**Verify Unchanged CTAs**:

```bash
# Navigate to homepage
mcp__playwright__browser_navigate({ url: "http://localhost:3000" })

# Scroll to "Payez uniquement ce que vous consommez" section
# Click on one of the 3 pricing cards CTAs

# Expected: Should navigate to /louis, /arthur, or /alexandra
# Should NOT open popup
```

**Expected Outcome**:
- ✅ PricingCardsHome CTAs still navigate to agent pages
- ✅ No popup opens on those CTAs
- ✅ Navigation works as before

---

### Loop 9: Accessibility Tests

```bash
# Open popup
# Press Tab repeatedly

# Expected: Focus moves through fields in order
# Expected: Focus stays trapped inside modal
# Expected: Focus outlines are visible (purple)

# Press Escape

# Expected: Modal closes
```

**Expected Outcome**:
- ✅ Keyboard navigation works
- ✅ Focus trap implemented
- ✅ Escape key closes modal
- ✅ ARIA labels present
- ✅ Screen reader compatible

---

### Loop 10: Success Flow End-to-End

```bash
# 1. Open popup from any of 4 CTAs
# 2. Fill all fields with valid data
# 3. Submit form
# 4. Verify:
#    - Loading spinner appears
#    - Button disabled during submit
#    - Popup closes on success
#    - Success toast appears bottom-right
#    - Toast message: "Vous allez recevoir un appel dans 30 secondes ! 🎙️"
#    - Toast auto-closes after 5 seconds
```

**Expected Outcome**:
- ✅ Complete flow works without errors
- ✅ UX feels smooth and professional
- ✅ User understands next step (appel sous 30s)

---

## ⚠️ Anti-patterns for Voipia

### ❌ DON'T

1. **Use href on Button with onClick**
   ```tsx
   // ❌ BAD: href conflicts with onClick
   <Button href="/#contact" onClick={() => setIsPopupOpen(true)}>
   ```

2. **Forget 'use client' directive**
   ```tsx
   // ❌ BAD: useState without 'use client'
   import { useState } from 'react';
   const Component = () => { /* ... */ }
   ```

3. **Install unnecessary dependencies**
   ```bash
   # ❌ BAD: Don't install react-phone-number-input
   # ❌ BAD: Don't install zustand for simple state
   # Use native HTML + useState instead
   ```

4. **Modify PricingCardsHome CTAs**
   ```tsx
   // ❌ BAD: Don't touch PricingCardsHome.tsx
   // Those CTAs must navigate to agent pages, not open popup
   ```

5. **Skip browser verification**
   ```bash
   # ❌ BAD: Trust code without visual check
   # ✅ ALWAYS use MCP Playwright to verify
   ```

6. **Hardcode z-index**
   ```tsx
   // ❌ BAD: z-index: 9999
   // ✅ GOOD: z-50 (Tailwind utility)
   ```

7. **Forget form reset**
   ```typescript
   // ❌ BAD: Leave form filled after success
   // ✅ GOOD: Reset formData on success
   ```

8. **Block UI during submit without feedback**
   ```tsx
   // ❌ BAD: Disabled button without spinner
   // ✅ GOOD: Loader2 icon + "Envoi en cours..."
   ```

---

## 📊 Success Criteria

### Functional ✅
- [ ] Popup opens on 4 CTAs (Header, Hero, CTAFinal, BundlePricing)
- [ ] Popup does NOT open on PricingCardsHome CTAs
- [ ] All 7 fields present and functional
- [ ] Validation works (HTML5 + custom patterns)
- [ ] Webhook integration successful (POST to n8n)
- [ ] Success toast appears and auto-closes
- [ ] Form resets after submission
- [ ] Error handling displays user-friendly messages

### UI/UX ✅
- [ ] Glassmorphism design consistent with site
- [ ] Animations smooth (Framer Motion)
- [ ] Responsive on mobile/tablet/desktop
- [ ] Focus states visible (purple border)
- [ ] Helper texts present where needed
- [ ] Icons displayed correctly (Lucide)
- [ ] Required asterisks red
- [ ] Button gradient violet-purple

### Technical ✅
- [ ] No TypeScript errors
- [ ] Lint passes (0 errors/warnings)
- [ ] Build succeeds (`npm run build`)
- [ ] No console errors
- [ ] Lighthouse Performance > 90
- [ ] Lighthouse Accessibility > 95
- [ ] No regression on existing features

### Business ✅
- [ ] Webhook triggers n8n workflow
- [ ] Payload contains all required data
- [ ] User receives clear next-step message
- [ ] Fallback contact info on error

---

## 📁 Files Changed Summary

### Created (2 files)
```
components/ui/CTAPopupForm.tsx    (~350 lines)
components/ui/SuccessToast.tsx    (~50 lines)
```

### Modified (4 files)
```
components/shared/Header.tsx       (+15 lines: imports, state, popup components)
components/landing/HeroHome.tsx    (+15 lines: imports, state, popup components)
components/landing/CTAFinal.tsx    (+15 lines: imports, state, popup components)
components/landing/BundlePricing.tsx (+15 lines: imports, state, popup components)
```

### Unchanged (3+ files)
```
components/landing/PricingCardsHome.tsx  (DO NOT TOUCH)
components/landing/Hero*.tsx              (Agent pages - DO NOT TOUCH)
components/landing/Pricing*.tsx           (Agent pages - DO NOT TOUCH)
```

---

## 🎯 Implementation Order

1. ✅ **Create CTAPopupForm.tsx** (~2h)
   - Copy structure from ContactModal.tsx
   - Implement 7 fields with validation
   - Add webhook integration
   - Test in isolation

2. ✅ **Create SuccessToast.tsx** (~15min)
   - Simple Framer Motion toast
   - Auto-close after 5s
   - Test in isolation

3. ✅ **Modify Header.tsx** (~10min)
   - Add imports
   - Add state
   - Replace button
   - Add popup + toast

4. ✅ **Modify HeroHome.tsx** (~10min)
   - Same pattern as Header

5. ✅ **Modify CTAFinal.tsx** (~10min)
   - Same pattern as Header

6. ✅ **Modify BundlePricing.tsx** (~10min)
   - Same pattern as Header

7. ✅ **Run all validation loops** (~1h)
   - Visual tests (Playwright)
   - Form validation tests
   - Webhook test
   - Responsive tests
   - Lint & build
   - Regression tests

8. ✅ **Fix any issues** (~30min buffer)

**Total Estimated Time**: 3-4 hours

---

## 💡 Notes & Tips

### Debugging Tips

**Popup doesn't open**:
- Check console for errors
- Verify 'use client' directive present
- Verify useState imported
- Check onClick handler syntax

**Form validation not working**:
- Check `required` attribute on inputs
- Check `pattern` attribute on website/email
- Verify validateForm() logic

**Webhook fails**:
- Check network tab for request
- Verify URL is exact: `https://n8n.voipia.fr/webhook/voipia_louis_from_site`
- Check payload format matches spec
- Test webhook independently with curl/Postman

**Styles broken**:
- Verify cn() imported from @/lib/utils
- Check Tailwind classes are valid
- Verify no typos in className strings
- Check backdrop-blur supported in browser

### Performance Optimizations

- ✅ AnimatePresence for smooth mount/unmount
- ✅ useEffect for body scroll lock (cleanup)
- ✅ Event listener cleanup (Escape key)
- ✅ Conditional rendering (isOpen guard)
- ✅ Single component per CTA (no global state overhead)

### Future Enhancements (Post-MVP)

- [ ] Google Places API for company autocomplete
- [ ] Real-time email validation (check domain MX records)
- [ ] Analytics tracking (GA4 events)
- [ ] A/B testing different copy
- [ ] Multi-step form (reduce cognitive load)
- [ ] Calendly integration post-submission

---

## 🚀 Ready to Execute

This PRP is **production-ready** and can be executed immediately.

**Confidence Score**: 9/10

**Rationale**:
- Complete specifications from INITIAL.md (1140 lines)
- Template exists (ContactModal.tsx)
- Clear validation loops defined
- Anti-patterns documented
- File paths exact and verified
- No ambiguity in requirements

**Missing 1 point for**:
- n8n webhook response format not 100% confirmed (assumed based on ContactModal pattern)

**Recommendation**: Execute this PRP to implement the feature, then iterate based on real webhook responses if needed.

---

**Generated**: 2025-01-20
**Version**: 1.0
**Status**: ✅ Ready for Execution
