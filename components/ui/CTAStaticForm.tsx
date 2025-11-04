'use client';

import React, { useState } from 'react';
import {
  Building,
  Globe,
  Briefcase,
  Mail,
  Phone,
  Loader2
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CTAStaticFormProps {
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

const CTAStaticForm: React.FC<CTAStaticFormProps> = ({ onSuccess }) => {
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

  const handleChange = (field: keyof FormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!validateForm(formData)) {
      setError('Veuillez remplir tous les champs correctement');
      return;
    }

    setIsSubmitting(true);

    try {
      const fullPhone = `${formData.countryCode}${formData.phone.replace(/\s/g, '')}`;

      const payload = {
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim(),
        company: formData.company.trim(),
        website: formData.website.trim(),
        industry: formData.industry,
        email: formData.email.trim().toLowerCase(),
        phone: fullPhone,
        source: 'landing_page_tester_nos_agents'
      };

      const response = await fetch('https://n8n.voipia.fr/webhook/voipia_louis_from_site', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error('Erreur lors de l\'envoi du formulaire');
      }

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

      onSuccess?.();
    } catch (err) {
      console.error('Form submission error:', err);
      setError('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isFormValid = validateForm(formData);

  return (
    <div className="w-full max-w-2xl mx-auto bg-gray-900/60 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-violet-600/20 to-purple-600/20 border-b border-white/10 p-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-3">
          <span className="text-3xl">🎙️</span>
          Testez votre futur Agent Vocal IA
        </h2>
      </div>

      {/* Form Content */}
      <div className="p-6 md:p-8">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Introduction */}
          <div className="space-y-3 text-white/80 text-sm leading-relaxed">
            <p>
              Testez notre agent vocal intelligent, capable de rappeler vos leads entrants,
              de les qualifier et de prendre des rendez-vous à votre place, 7j/7, en toute autonomie.
            </p>
            <p className="font-medium">Laissez vos coordonnées ci-dessous :</p>
            <p className="flex items-start gap-2">
              <span className="text-lg">👉</span>
              <span>Notre agent vous appellera dans les 30 prochaines secondes pour une démonstration automatique.</span>
            </p>
            <p className="flex items-start gap-2">
              <span className="text-lg">👉</span>
              <span>Vous pourrez ensuite réserver un créneau avec Rémi (Co-Fondateur VoIPIA) pour parler de son implémentation dans votre organisation.</span>
            </p>
          </div>

          {/* Name fields */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <FormField label="Prénom" required>
              <input
                type="text"
                value={formData.firstName}
                onChange={(e) => handleChange('firstName', e.target.value)}
                placeholder="Jean"
                required
                className={cn(
                  "w-full px-4 py-2 bg-black/30 border border-white/10",
                  "rounded-lg text-white placeholder:text-white/30",
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
                className={cn(
                  "w-full px-4 py-2 bg-black/30 border border-white/10",
                  "rounded-lg text-white placeholder:text-white/30",
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
              className={cn(
                "w-full px-4 py-2 bg-black/30 border border-white/10",
                "rounded-lg text-white placeholder:text-white/30",
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
              className={cn(
                "w-full px-4 py-2 bg-black/30 border border-white/10",
                "rounded-lg text-white placeholder:text-white/30",
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
              style={{ colorScheme: 'dark' }}
              className={cn(
                "w-full px-4 py-2 bg-black/30 border border-white/10",
                "rounded-lg text-white",
                "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                "transition-colors appearance-none cursor-pointer",
                "bg-[url('data:image/svg+xml;charset=UTF-8,%3csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2012%2012%22%3e%3cpath%20fill%3D%22%23ffffff66%22%20d%3D%22M10.293%203.293L6%207.586%201.707%203.293A1%201%200%200%200%20.293%204.707l5%205a1%201%200%200%200%201.414%200l5-5a1%201%200%201%200-1.414-1.414z%22%2F%3e%3c%2Fsvg%3e')]",
                "bg-[length:1rem] bg-[right_1rem_center] bg-no-repeat",
                "[&>option]:bg-gray-900 [&>option]:text-white"
              )}
            >
              {INDUSTRIES.map((ind) => (
                <option
                  key={ind.value}
                  value={ind.value}
                  disabled={ind.disabled}
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
                "rounded-lg text-white placeholder:text-white/30",
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
                  "px-3 py-2 bg-black/30 border border-white/10",
                  "rounded-lg text-white",
                  "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                  "transition-colors cursor-pointer"
                )}
              >
                {COUNTRY_CODES.map((code) => (
                  <option key={code.value} value={code.value}>
                    {code.label}
                  </option>
                ))}
              </select>
              <input
                type="tel"
                value={formData.phone}
                onChange={(e) => handleChange('phone', e.target.value)}
                placeholder="6 66 62 82 99"
                required
                className={cn(
                  "flex-1 px-4 py-2 bg-black/30 border border-white/10",
                  "rounded-lg text-white placeholder:text-white/30",
                  "focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20",
                  "transition-colors"
                )}
              />
            </div>
          </FormField>

          {/* Error message */}
          {error && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
              <p className="text-sm text-red-400">{error}</p>
            </div>
          )}

          {/* Submit button */}
          <button
            type="submit"
            disabled={!isFormValid || isSubmitting}
            className={cn(
              "w-full py-3 rounded-lg font-semibold text-base",
              "bg-gradient-to-r from-violet-600 to-purple-600",
              "hover:from-violet-700 hover:to-purple-700",
              "disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed disabled:opacity-50",
              "transition-all duration-200",
              "flex items-center justify-center gap-2"
            )}
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                <span>Envoi en cours...</span>
              </>
            ) : (
              <span>Lancer la démonstration ✨</span>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default CTAStaticForm;
