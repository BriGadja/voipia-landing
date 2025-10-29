'use client';

import { useState } from 'react';
import { Mail, Phone, Building, User, Send } from 'lucide-react';

export default function CTAFinal() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    company: ''
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Intégrer avec le formulaire Fillout ou API
    console.log('Form submitted:', formData);
    alert('Merci ! Nous vous recontactons sous 24h.');
  };

  return (
    <section id="demo" className="py-20 bg-gradient-to-b from-black to-violet-950/20">
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-gradient-to-br from-violet-950/40 to-blue-950/40 backdrop-blur-lg border border-violet-500/30 rounded-3xl p-12">
          {/* Header */}
          <div className="text-center mb-12">
            <h2 className="text-5xl font-bold mb-4">
              Prêt à automatiser votre CRM ?
            </h2>
            <p className="text-xl text-gray-300">
              Essayez VoIPIA gratuitement pendant 14 jours. Sans carte bancaire.
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-2">
                  <User className="w-4 h-4 text-blue-400" />
                  Nom complet *
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="Jean Dupont"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>

              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-2">
                  <Mail className="w-4 h-4 text-blue-400" />
                  Email professionnel *
                </label>
                <input
                  type="email"
                  required
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="jean@entreprise.fr"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                />
              </div>

              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-2">
                  <Phone className="w-4 h-4 text-blue-400" />
                  Téléphone *
                </label>
                <input
                  type="tel"
                  required
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="06 12 34 56 78"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                />
              </div>

              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-2">
                  <Building className="w-4 h-4 text-blue-400" />
                  Entreprise *
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="Mon Entreprise SAS"
                  value={formData.company}
                  onChange={(e) => setFormData({ ...formData, company: e.target.value })}
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full py-4 bg-gradient-to-r from-blue-500 to-violet-500 rounded-xl font-bold text-lg hover:opacity-90 transition-opacity flex items-center justify-center gap-2"
            >
              <Send className="w-5 h-5" />
              Demander ma démo gratuite →
            </button>

            <p className="text-center text-sm text-gray-400">
              Réponse sous 24h • Pas de spam • Données sécurisées
            </p>
          </form>

          {/* Trust badges */}
          <div className="mt-12 pt-8 border-t border-white/10">
            <div className="grid md:grid-cols-3 gap-6 text-center text-sm text-gray-300">
              <div>
                ✓ <span className="font-semibold">14 jours d&apos;essai</span><br />
                Sans carte bancaire
              </div>
              <div>
                ✓ <span className="font-semibold">Support français</span><br />
                Disponible 24/7
              </div>
              <div>
                ✓ <span className="font-semibold">Déploiement rapide</span><br />
                Opérationnel en 5 jours
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
