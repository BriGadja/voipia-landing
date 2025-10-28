'use client';

import { Button } from '@/components/shared/Button';
import { Phone, Play } from 'lucide-react';

export function CTAIntermediate() {
  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-r from-blue-900/20 via-cyan-900/10 to-blue-900/20" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <h2 className="text-4xl md:text-5xl font-bold text-white">
            Découvrez Louis en action
          </h2>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700">
              <Phone className="w-5 h-5 mr-2" />
              Appeler Louis maintenant
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un exemple d&apos;appel
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
