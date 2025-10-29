'use client';

import { Button } from '@/components/shared/Button';
import { Phone, Play } from 'lucide-react';

export function CTAFinalAlexandra() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background gradient avec vert Alexandra */}
      <div className="absolute inset-0 bg-gradient-to-br from-green-900/20 via-emerald-900/10 to-green-900/20" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center">

          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 leading-tight">
            <span className="text-white">Ne manquez plus jamais un appel</span>
            <br />
            <span className="bg-gradient-to-r from-green-400 to-emerald-400 bg-clip-text text-transparent">
              dès aujourd&apos;hui
            </span>
          </h2>

          <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto">
            Testez gratuitement Alexandra et découvrez comment elle peut transformer votre accueil téléphonique en moins d&apos;une semaine.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700">
              <Phone className="w-5 h-5 mr-2" />
              Tester gratuitement Alexandra
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel d&apos;Alexandra
            </Button>
          </div>

        </div>
      </div>
    </section>
  );
}
