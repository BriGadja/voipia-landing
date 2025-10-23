'use client';

import { ArrowRight } from 'lucide-react';

export default function HowItWorks() {
  const steps = [
    {
      number: "1",
      title: "Lead entrant",
      description: "Un nouveau lead arrive sur votre site ou votre CRM",
      time: "11h00"
    },
    {
      number: "2",
      title: "Louis appelle",
      description: "Louis rappelle automatiquement en moins de 30 secondes",
      time: "11h01"
    },
    {
      number: "3",
      title: "RDV pris ou NRP",
      description: "Louis qualifie, pose le RDV ou laisse un message",
      time: "11h03"
    },
    {
      number: "4",
      title: "Arthur relance",
      description: "Si NRP, Arthur relance automatiquement jusqu'à RDV",
      time: "11h30, 16h00, J+2..."
    }
  ];

  return (
    <section id="comment-ca-marche" className="py-20 bg-gradient-to-b from-black to-blue-950/10">
      <div className="max-w-6xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-16">
          <h2 className="text-5xl font-bold mb-4">
            Votre CRM devient une machine autonome
          </h2>
          <p className="text-xl text-gray-300">
            Du lead entrant au RDV posé, tout est automatisé
          </p>
        </div>

        {/* Timeline */}
        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-8 md:left-1/2 top-0 bottom-0 w-1 bg-gradient-to-b from-blue-500 via-violet-500 to-green-500 transform -translate-x-1/2 hidden md:block" />

          {/* Steps */}
          <div className="space-y-12">
            {steps.map((step, index) => (
              <div
                key={index}
                className={`relative flex flex-col md:flex-row items-start md:items-center gap-8 ${
                  index % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'
                }`}
              >
                {/* Content */}
                <div className={`flex-1 ${index % 2 === 0 ? 'md:text-right' : 'md:text-left'}`}>
                  <div className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-6">
                    <div className="text-sm text-violet-400 font-semibold mb-2">{step.time}</div>
                    <h3 className="text-2xl font-bold mb-2">{step.title}</h3>
                    <p className="text-gray-300">{step.description}</p>
                  </div>
                </div>

                {/* Number Circle */}
                <div className="relative z-10 flex-shrink-0">
                  <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-violet-500 rounded-full flex items-center justify-center text-2xl font-bold border-4 border-black">
                    {step.number}
                  </div>
                </div>

                {/* Spacer */}
                <div className="flex-1 hidden md:block" />
              </div>
            ))}
          </div>
        </div>

        {/* Video placeholder */}
        <div className="mt-16 bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-12 text-center">
          <div className="text-6xl mb-4">🎥</div>
          <h3 className="text-2xl font-bold mb-2">Voir le workflow en action</h3>
          <p className="text-gray-300 mb-6">
            Vidéo explicative (30-60 secondes) montrant le processus complet
          </p>
          {/* Placeholder pour vidéo */}
          <div className="aspect-video bg-black/50 rounded-xl flex items-center justify-center">
            <p className="text-gray-500">Vidéo à venir : /public/videos/workflow-crm.mp4</p>
          </div>
        </div>

        {/* CTA */}
        <div className="mt-12 text-center">
          <a
            href="#demo"
            className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-500 to-violet-500 rounded-xl font-bold text-lg hover:opacity-90 transition-opacity"
          >
            Je veux cette machine
            <ArrowRight className="w-5 h-5" />
          </a>
        </div>
      </div>
    </section>
  );
}
