'use client';

import { useState } from 'react';
import { Phone, Sparkles } from 'lucide-react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

export function CTAWebcall() {
  const [isPopupOpen, setIsPopupOpen] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);

  return (
    <section className="relative py-20 overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-gray-950 via-violet-950/20 to-gray-950" />

      {/* Decorative elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-violet-500/10 rounded-full blur-3xl" />
        <div className="absolute top-1/4 right-1/4 w-[300px] h-[300px] bg-purple-500/10 rounded-full blur-3xl" />
      </div>

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-3xl mx-auto text-center space-y-8">

          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20">
            <Sparkles className="w-4 h-4 text-violet-400" />
            <span className="text-sm text-violet-300 font-medium">Testez Louis en 30 secondes</span>
          </div>

          {/* Heading */}
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-white">
            Recevez un appel de démonstration{' '}
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              maintenant
            </span>
          </h2>

          {/* Description */}
          <p className="text-lg text-gray-400 max-w-2xl mx-auto">
            Découvrez comment Louis qualifie vos prospects et prend des rendez-vous.
            Entrez votre numéro et recevez un appel de démonstration immédiat.
          </p>

          {/* CTA Button */}
          <div className="flex justify-center pt-4">
            <button
              onClick={() => setIsPopupOpen(true)}
              className="group relative inline-flex items-center gap-3 px-8 py-4 bg-gradient-to-r from-violet-600 to-purple-600 rounded-xl text-lg font-semibold text-white hover:from-violet-500 hover:to-purple-500 transition-all duration-300 shadow-lg shadow-violet-500/25 hover:shadow-violet-500/40 hover:scale-105"
            >
              <Phone className="w-5 h-5" />
              <span>TESTER LOUIS MAINTENANT</span>

              {/* Animated ring */}
              <span className="absolute -inset-1 rounded-xl bg-gradient-to-r from-violet-600 to-purple-600 opacity-0 group-hover:opacity-20 blur transition-opacity" />
            </button>
          </div>

          {/* Trust indicators */}
          <div className="flex flex-wrap justify-center gap-6 pt-4 text-sm text-gray-500">
            <span className="flex items-center gap-2">
              <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              Gratuit, sans engagement
            </span>
            <span className="flex items-center gap-2">
              <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              Appel en moins de 30 secondes
            </span>
          </div>

        </div>
      </div>

      {/* Popup & Toast */}
      <CTAPopupForm
        isOpen={isPopupOpen}
        onClose={() => setIsPopupOpen(false)}
        onSuccess={() => setShowSuccessToast(true)}
      />

      <SuccessToast
        show={showSuccessToast}
        message="Vous allez recevoir un appel dans 30 secondes !"
        onClose={() => setShowSuccessToast(false)}
      />
    </section>
  );
}
