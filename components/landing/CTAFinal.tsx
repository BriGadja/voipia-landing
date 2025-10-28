'use client';

import { Button } from '@/components/shared/Button';
import { ArrowRight, Sparkles, Phone } from 'lucide-react';

export function CTAFinal() {
  return (
    <section className="py-24 relative overflow-hidden">
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
            Rejoignez plus de 50 entreprises qui ont déjà automatisé leurs appels avec VoIPIA.
            <br className="hidden md:block" />
            Sans engagement, sans carte bancaire.
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
            <Button size="lg" className="group shadow-2xl shadow-violet-500/30 hover:shadow-violet-500/50">
              <Phone className="w-5 h-5 mr-2" />
              Démarrer gratuitement
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </Button>
            <Button size="lg" variant="secondary">
              Réserver une démo
            </Button>
          </div>

          {/* Trust signals */}
          <div className="flex flex-wrap justify-center items-center gap-6 md:gap-12 pt-8 border-t border-white/10">
            <div className="flex items-center gap-2 text-sm text-gray-400">
              <div className="w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center">
                <div className="w-3 h-3 rounded-full bg-green-500" />
              </div>
              <span>Configuration en 10 minutes</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-400">
              <div className="w-6 h-6 rounded-full bg-blue-500/20 flex items-center justify-center">
                <div className="w-3 h-3 rounded-full bg-blue-500" />
              </div>
              <span>Support 7j/7 inclus</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-400">
              <div className="w-6 h-6 rounded-full bg-violet-500/20 flex items-center justify-center">
                <div className="w-3 h-3 rounded-full bg-violet-500" />
              </div>
              <span>Résiliable à tout moment</span>
            </div>
          </div>

          {/* Social proof numbers */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-16 pt-16 border-t border-white/10">
            <div>
              <p className="text-4xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent mb-2">
                50+
              </p>
              <p className="text-sm text-gray-400">Entreprises clientes</p>
            </div>
            <div>
              <p className="text-4xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent mb-2">
                +72%
              </p>
              <p className="text-sm text-gray-400">Taux de contact moyen</p>
            </div>
            <div>
              <p className="text-4xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent mb-2">
                800%
              </p>
              <p className="text-sm text-gray-400">ROI moyen</p>
            </div>
            <div>
              <p className="text-4xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent mb-2">
                4.9/5
              </p>
              <p className="text-sm text-gray-400">Satisfaction client</p>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
}
