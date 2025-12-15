'use client';

import { Quote, Play, Star } from 'lucide-react';

// Placeholders - À remplacer par les vrais témoignages
const testimonials = [
  {
    id: 1,
    name: 'Prénom Nom',
    role: 'Directeur Commercial',
    company: 'Entreprise 1',
    content: 'Placeholder pour le témoignage client. Ce texte sera remplacé par le vrai témoignage fourni par le client.',
    rating: 5,
    image: null, // URL de la photo à ajouter
  },
  {
    id: 2,
    name: 'Prénom Nom',
    role: 'Gérant',
    company: 'Entreprise 2',
    content: 'Placeholder pour le témoignage client. Ce texte sera remplacé par le vrai témoignage fourni par le client.',
    rating: 5,
    image: null,
  },
  {
    id: 3,
    name: 'Prénom Nom',
    role: 'Responsable Agence',
    company: 'Entreprise 3',
    content: 'Placeholder pour le témoignage client. Ce texte sera remplacé par le vrai témoignage fourni par le client.',
    rating: 5,
    image: null,
  },
];

// Placeholders pour les vidéos YouTube - À remplacer par les vrais liens
const videoTestimonials = [
  {
    id: 1,
    name: 'Yassine',
    company: 'Placeholder',
    youtubeId: null, // ID de la vidéo YouTube à ajouter (ex: 'dQw4w9WgXcQ')
    thumbnail: null, // URL de la thumbnail personnalisée
  },
  {
    id: 2,
    name: 'Valentin',
    company: 'Placeholder',
    youtubeId: null,
    thumbnail: null,
  },
];

export function TestimonialsSection() {
  return (
    <section className="py-24 bg-gray-950">
      <div className="container mx-auto px-4">

        {/* Section header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-white mb-4">
            Ce que disent{' '}
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              nos clients
            </span>
          </h2>
          <p className="text-lg text-gray-400 max-w-2xl mx-auto">
            Découvrez comment VoIPIA transforme le quotidien de nos clients
          </p>
        </div>

        {/* Two columns layout */}
        <div className="grid lg:grid-cols-2 gap-12">

          {/* Left column - Written testimonials */}
          <div className="space-y-6">
            <h3 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
              <Quote className="w-5 h-5 text-violet-400" />
              Témoignages
            </h3>

            {testimonials.map((testimonial) => (
              <div
                key={testimonial.id}
                className="p-6 rounded-2xl bg-white/5 border border-white/10 hover:border-violet-500/30 transition-all"
              >
                {/* Rating */}
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: testimonial.rating }).map((_, i) => (
                    <Star key={i} className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                  ))}
                </div>

                {/* Quote */}
                <p className="text-gray-300 mb-6 italic">
                  &ldquo;{testimonial.content}&rdquo;
                </p>

                {/* Author */}
                <div className="flex items-center gap-4">
                  {/* Avatar placeholder */}
                  <div className="w-12 h-12 rounded-full bg-gradient-to-r from-violet-500 to-purple-500 flex items-center justify-center text-white font-semibold">
                    {testimonial.name.charAt(0)}
                  </div>
                  <div>
                    <p className="font-semibold text-white">{testimonial.name}</p>
                    <p className="text-sm text-gray-400">
                      {testimonial.role} - {testimonial.company}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Right column - Video testimonials */}
          <div className="space-y-6">
            <h3 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
              <Play className="w-5 h-5 text-violet-400" />
              Vidéos témoignages
            </h3>

            {videoTestimonials.map((video) => (
              <div
                key={video.id}
                className="relative rounded-2xl overflow-hidden bg-white/5 border border-white/10 hover:border-violet-500/30 transition-all group"
              >
                {/* Video thumbnail placeholder */}
                <div className="aspect-video bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center">
                  {video.youtubeId ? (
                    // YouTube embed when video ID is provided
                    <iframe
                      className="w-full h-full"
                      src={`https://www.youtube.com/embed/${video.youtubeId}`}
                      title={`Témoignage de ${video.name}`}
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowFullScreen
                    />
                  ) : (
                    // Placeholder when no video
                    <div className="text-center">
                      <div className="w-16 h-16 rounded-full bg-violet-600/20 flex items-center justify-center mx-auto mb-4 group-hover:bg-violet-600/30 transition-colors">
                        <Play className="w-8 h-8 text-violet-400 ml-1" />
                      </div>
                      <p className="text-gray-400 text-sm">
                        Vidéo de {video.name} - À venir
                      </p>
                    </div>
                  )}
                </div>

                {/* Video info */}
                <div className="p-4">
                  <p className="font-semibold text-white">{video.name}</p>
                  <p className="text-sm text-gray-400">{video.company}</p>
                </div>
              </div>
            ))}

            {/* Note for adding more videos */}
            <div className="p-4 rounded-xl bg-violet-500/10 border border-violet-500/20 text-center">
              <p className="text-sm text-violet-300">
                Plus de témoignages vidéo à venir...
              </p>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
}
