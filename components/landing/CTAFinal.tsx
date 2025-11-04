'use client';

import { useState } from 'react';
import { Button } from '@/components/shared/Button';
import { ArrowRight, Sparkles, Phone } from 'lucide-react';
import CTAPopupForm from '@/components/ui/CTAPopupForm';
import SuccessToast from '@/components/ui/SuccessToast';

export function CTAFinal() {
  const [isPopupOpen, setIsPopupOpen] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);
  return (
    <section className="py-16 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-br from-violet-900/20 via-purple-900/10 to-pink-900/5" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-violet-600/10 via-transparent to-transparent" />

      {/* Animated grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff05_1px,transparent_1px),linear-gradient(to_bottom,#ffffff05_1px,transparent_1px)] bg-[size:3rem_3rem] animate-pulse" />

      <div className="container mx-auto px-4 relative z-10">

        <div className="max-w-4xl mx-auto text-center">

          {/* Floating badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-8 animate-bounce">
            <Sparkles className="w-4 h-4 text-violet-400" />
            <span className="text-sm font-semibold text-violet-300">
              Offre de lancement : 1er mois offert
            </span>
          </div>

          {/* Main heading */}
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 leading-tight">
            <span className="text-white">Prêt à transformer</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              vos appels en résultats ?
            </span>
          </h2>

          <p className="text-xl md:text-2xl text-gray-300 mb-12 max-w-3xl mx-auto leading-relaxed">
            Rejoignez les entreprises qui font confiance à VoIPIA pour gérer leurs appels, relances et rendez-vous automatiquement.
            <br className="hidden md:block" />
            Sans engagement, sans carte bancaire.
          </p>

          {/* CTA */}
          <div className="flex justify-center items-center mb-12">
            <Button size="lg" className="shadow-2xl shadow-violet-500/30 hover:shadow-violet-500/50" onClick={() => setIsPopupOpen(true)}>
              TESTER NOS AGENTS
            </Button>
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
        message="Vous allez recevoir un appel dans 30 secondes ! 🎙️"
        onClose={() => setShowSuccessToast(false)}
      />
    </section>
  );
}
