'use client';

import { Star } from 'lucide-react';

export default function Testimonials() {
  const testimonials = [
    {
      name: "Thomas Dubois",
      role: "CEO, Immobilier Plus",
      content: "Nous avons multiplié par 3 notre taux de RDV posés. Louis rappelle nos leads en moins de 2 minutes, 24/7. C'est incroyable.",
      result: "+187% RDV posés",
      avatar: "TD"
    },
    {
      name: "Sophie Martin",
      role: "Directrice Commerciale, TechSolutions",
      content: "Arthur a réactivé 42% de notre base dormante. Des milliers de leads qu'on pensait perdus sont devenus clients.",
      result: "42% base réactivée",
      avatar: "SM"
    },
    {
      name: "Marc Lefebvre",
      role: "Fondateur, Energy Consult",
      content: "ROI de 850% en 6 mois. VoIPIA a remplacé 3 commerciaux juniors et fait mieux qu'eux. C'est notre meilleur investissement 2024.",
      result: "ROI 850% en 6 mois",
      avatar: "ML"
    }
  ];

  return (
    <section className="py-20 bg-black">
      <div className="max-w-6xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold mb-4">
            Ils ont arrêté de perdre des leads
          </h2>
          <p className="text-xl text-gray-300">
            +200 entreprises font confiance à VoIPIA
          </p>
        </div>

        {/* Testimonials Grid */}
        <div className="grid md:grid-cols-3 gap-8 mb-12">
          {testimonials.map((testimonial, index) => (
            <div key={index} className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-8">
              {/* Stars */}
              <div className="flex gap-1 mb-4">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="w-5 h-5 fill-yellow-400 text-yellow-400" />
                ))}
              </div>

              {/* Content */}
              <p className="text-gray-300 mb-6 italic">
                &quot;{testimonial.content}&quot;
              </p>

              {/* Result Badge */}
              <div className="bg-gradient-to-r from-green-500/20 to-blue-500/20 border border-green-500/30 rounded-lg px-4 py-2 mb-6 text-center">
                <div className="text-green-400 font-bold">{testimonial.result}</div>
              </div>

              {/* Author */}
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-violet-500 flex items-center justify-center font-bold">
                  {testimonial.avatar}
                </div>
                <div>
                  <div className="font-semibold">{testimonial.name}</div>
                  <div className="text-sm text-gray-400">{testimonial.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Metrics Banner */}
        <div className="bg-gradient-to-r from-violet-950/40 to-blue-950/40 backdrop-blur-lg border border-violet-500/30 rounded-2xl p-8">
          <div className="grid md:grid-cols-3 gap-8 text-center">
            <div>
              <div className="text-5xl font-bold text-violet-400 mb-2">+50k</div>
              <div className="text-gray-300">Appels traités</div>
            </div>
            <div>
              <div className="text-5xl font-bold text-blue-400 mb-2">92%</div>
              <div className="text-gray-300">Taux de contact</div>
            </div>
            <div>
              <div className="text-5xl font-bold text-green-400 mb-2">2min</div>
              <div className="text-gray-300">Durée moyenne</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
