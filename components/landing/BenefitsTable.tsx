'use client';

import { Card } from '@/components/shared/Card';
import type { LucideIcon } from 'lucide-react';

export interface BenefitItem {
  label: string;
  value: string;
  icon: LucideIcon;
}

interface BenefitsTableProps {
  benefits: BenefitItem[];
  title?: string;
  subtitle?: string;
  gradientFrom?: string;
  gradientTo?: string;
}

export function BenefitsTable({
  benefits,
  title = "Des résultats qui parlent d'eux-mêmes",
  subtitle = "Chaque lead est traité. Chaque opportunité est exploitée.",
  gradientFrom = 'from-blue-400',
  gradientTo = 'to-cyan-400',
}: BenefitsTableProps) {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            {title}
          </h2>
          <p className="text-xl text-gray-300">
            {subtitle}
          </p>
        </div>

        {/* Benefits table */}
        <Card variant="gradient" className="max-w-4xl mx-auto overflow-hidden">
          <div className="divide-y divide-white/10">
            {benefits.map((benefit, idx) => (
              <div
                key={idx}
                className="p-6 flex items-center justify-between gap-6 hover:bg-white/5 transition-colors"
              >
                {/* Left: Label with icon */}
                <div className="flex items-center gap-4">
                  <div className={`w-10 h-10 rounded-lg bg-gradient-to-br ${gradientFrom.replace('from-', 'from-').replace('-400', '-500')} ${gradientTo.replace('to-', 'to-').replace('-400', '-500')} flex items-center justify-center flex-shrink-0`}>
                    <benefit.icon className="w-5 h-5 text-white" />
                  </div>
                  <p className="text-gray-300 font-medium">
                    {benefit.label}
                  </p>
                </div>

                {/* Right: Value */}
                <p className={`text-2xl md:text-3xl font-bold bg-gradient-to-r ${gradientFrom} ${gradientTo} bg-clip-text text-transparent whitespace-nowrap`}>
                  {benefit.value}
                </p>
              </div>
            ))}
          </div>
        </Card>

      </div>
    </section>
  );
}
