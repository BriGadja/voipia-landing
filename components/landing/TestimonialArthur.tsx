'use client';

import { Card } from '@/components/shared/Card';
import { testimonials } from '@/lib/data/testimonials';
import { Quote } from 'lucide-react';

export function TestimonialArthur() {
  const testimonial = testimonials.arthur;

  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Ne nous croyez pas seulement sur parole...
          </h2>
        </div>

        <Card variant="gradient" className="max-w-5xl mx-auto p-12">
          {/* Quote icon */}
          <div className="flex justify-center mb-6">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center">
              <Quote className="w-8 h-8 text-white" />
            </div>
          </div>

          {/* Citation */}
          <blockquote className="text-xl md:text-2xl text-gray-200 leading-relaxed mb-8 italic text-center">
            &quot;{testimonial.quote}&quot;
          </blockquote>

          {/* Auteur */}
          <div className="flex flex-col items-center gap-2 mb-8">
            <p className="font-bold text-white text-lg">{testimonial.author}</p>
            <p className="text-sm text-gray-400">{testimonial.role}, {testimonial.company}</p>
          </div>

          {/* Métriques */}
          {testimonial.metrics && testimonial.metrics.length > 0 && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pt-8 border-t border-white/10">
              {testimonial.metrics.map((metric, idx) => (
                <div key={idx} className="text-center">
                  <p className="text-3xl md:text-4xl font-bold bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
                    {metric.value}
                  </p>
                  <p className="text-sm text-gray-400 mt-2">{metric.label}</p>
                </div>
              ))}
            </div>
          )}
        </Card>

      </div>
    </section>
  );
}
