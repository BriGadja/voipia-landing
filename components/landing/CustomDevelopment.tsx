'use client';

import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Code2, Rocket, Headphones } from 'lucide-react';

export function CustomDevelopment() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-br from-cyan-900/10 via-blue-900/5 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">

        <Card variant="gradient" className="max-w-5xl mx-auto p-12 border-2 border-cyan-500/20">
          <div className="grid md:grid-cols-2 gap-12 items-center">

            {/* Left: Content */}
            <div className="space-y-6">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-500/10 border border-cyan-500/20">
                <Code2 className="w-4 h-4 text-cyan-400" />
                <span className="text-sm font-semibold text-cyan-300">
                  Sur-mesure
                </span>
              </div>

              <h2 className="text-3xl md:text-4xl font-bold">
                <span className="text-white">Besoin d&apos;un développement</span>
                <br />
                <span className="bg-gradient-to-r from-cyan-400 to-blue-400 bg-clip-text text-transparent">
                  personnalisé ?
                </span>
              </h2>

              <p className="text-lg text-gray-300 leading-relaxed">
                Nos experts développent des solutions IA vocales sur-mesure pour vos cas d&apos;usage spécifiques :
                workflows complexes, intégrations customs, multi-agents, etc.
              </p>

              <div className="space-y-4 pt-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-500 flex items-center justify-center flex-shrink-0">
                    <Rocket className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <p className="font-semibold text-white mb-1">Développement rapide</p>
                    <p className="text-sm text-gray-400">POC en 2 semaines, production en 4-6 semaines</p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-500 flex items-center justify-center flex-shrink-0">
                    <Headphones className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <p className="font-semibold text-white mb-1">Support dédié</p>
                    <p className="text-sm text-gray-400">Un expert technique disponible 7j/7</p>
                  </div>
                </div>
              </div>

              <div className="pt-6">
                <Button size="lg" className="bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700">
                  Discuter de mon projet
                </Button>
              </div>
            </div>

            {/* Right: Visual */}
            <div className="relative">
              {/* Code window mockup */}
              <div className="bg-gray-900 rounded-lg border border-white/10 overflow-hidden shadow-2xl">
                {/* Window header */}
                <div className="bg-gray-800 px-4 py-3 border-b border-white/10 flex items-center gap-2">
                  <div className="flex gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-500" />
                    <div className="w-3 h-3 rounded-full bg-yellow-500" />
                    <div className="w-3 h-3 rounded-full bg-green-500" />
                  </div>
                  <p className="text-xs text-gray-400 font-mono ml-4">custom-workflow.ts</p>
                </div>

                {/* Code content */}
                <div className="p-6 font-mono text-sm space-y-2">
                  <p className="text-gray-500">{`// Exemple de workflow custom`}</p>
                  <p className="text-cyan-400">
                    <span className="text-purple-400">const</span> workflow = <span className="text-yellow-400">{`{`}</span>
                  </p>
                  <p className="text-gray-300 pl-4">
                    trigger: <span className="text-green-400">&quot;new_lead&quot;</span>,
                  </p>
                  <p className="text-gray-300 pl-4">
                    agents: [<span className="text-orange-400">&quot;louis&quot;</span>, <span className="text-orange-400">&quot;arthur&quot;</span>],
                  </p>
                  <p className="text-gray-300 pl-4">
                    rules: <span className="text-yellow-400">{`{`}</span>
                  </p>
                  <p className="text-gray-300 pl-8">
                    qualification: <span className="text-blue-400">true</span>,
                  </p>
                  <p className="text-gray-300 pl-8">
                    rdv_auto: <span className="text-blue-400">true</span>,
                  </p>
                  <p className="text-gray-300 pl-4">
                    <span className="text-yellow-400">{`}`}</span>,
                  </p>
                  <p className="text-yellow-400">
                    {`}`};
                  </p>
                  <p className="text-gray-500 pt-2">{`// Intégration CRM custom`}</p>
                  <p className="text-cyan-400">
                    <span className="text-purple-400">await</span> syncToCRM(workflow);
                  </p>
                </div>
              </div>

              {/* Floating badge */}
              <div className="absolute -top-4 -right-4 bg-gradient-to-r from-cyan-600 to-blue-600 text-white px-4 py-2 rounded-lg shadow-lg text-sm font-semibold">
                100% flexible
              </div>
            </div>

          </div>
        </Card>

      </div>
    </section>
  );
}
