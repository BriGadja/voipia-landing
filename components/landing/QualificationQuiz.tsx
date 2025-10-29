'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card } from '@/components/shared/Card';
import { Sparkles } from 'lucide-react';

const questions = [
  {
    id: 1,
    question: 'Quel est votre principal défi commercial ?',
    options: [
      {
        label: 'Rappeler rapidement mes nouveaux leads',
        description: 'Vous générez des leads mais perdez du temps à les rappeler',
        value: 'louis',
        icon: '📞',
      },
      {
        label: 'Réactiver mes prospects dormants',
        description: 'Vous avez une base de contacts inexploitée',
        value: 'arthur',
        icon: '🔄',
      },
      {
        label: 'Répondre à tous mes appels entrants',
        description: 'Vous manquez des appels importants',
        value: 'alexandra',
        icon: '☎️',
      },
    ],
  },
];

export function QualificationQuiz() {
  const router = useRouter();
  const [step] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);

  const handleAnswer = (value: string) => {
    setIsAnimating(true);

    // Animation + redirection
    setTimeout(() => {
      router.push(`/${value}`);
    }, 300);
  };

  const currentQuestion = questions[step];

  return (
    <section className="py-20 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-violet-900/10 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-3xl mx-auto">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-6">
              <Sparkles className="w-4 h-4 text-violet-400" />
              <span className="text-sm font-semibold text-violet-300">
                Orientation personnalisée
              </span>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              <span className="text-white">Quel agent IA</span>
              <br />
              <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
                répond le mieux à votre besoin ?
              </span>
            </h2>
            <p className="text-lg text-gray-300">
              Répondez en 1 clic pour découvrir la solution idéale
            </p>
          </div>

          {/* Quiz Card */}
          <Card variant="gradient" className="p-8">
            <div className="mb-8">
              <p className="text-xl font-semibold text-white mb-2">
                {currentQuestion.question}
              </p>
              <p className="text-sm text-gray-400">
                Choisissez l&apos;option qui correspond le mieux à votre situation
              </p>
            </div>

            <div className="space-y-4">
              {currentQuestion.options.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleAnswer(option.value)}
                  disabled={isAnimating}
                  className="w-full p-6 text-left rounded-lg border border-white/20 hover:border-white/40 hover:bg-white/5 transition-all group disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <div className="flex items-start gap-4">
                    <span className="text-4xl">{option.icon}</span>
                    <div className="flex-1">
                      <p className="font-semibold text-lg text-white mb-1 group-hover:text-violet-400 transition-colors">
                        {option.label}
                      </p>
                      <p className="text-sm text-gray-400">
                        {option.description}
                      </p>
                    </div>
                    <span className="text-violet-400 opacity-0 group-hover:opacity-100 transition-opacity">
                      →
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </Card>

          {/* Footer */}
          <p className="text-center text-sm text-gray-400 mt-6">
            Pas sûr de votre choix ? <button className="text-violet-400 hover:underline">Découvrez tous nos agents</button>
          </p>
        </div>
      </div>
    </section>
  );
}
