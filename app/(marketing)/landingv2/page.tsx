export default function LandingV2Page() {
  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <h1 className="text-5xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
          Nouvelle Home Page Voipia (v2)
        </h1>
        <p className="text-xl text-gray-400 max-w-2xl mx-auto">
          Structure en cours de construction - Phase 1 : Fondations
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-violet-500/10 border border-violet-500/20">
          <span className="text-2xl">📍</span>
          <span className="text-violet-400 font-mono text-sm">
            URL de développement : /landingv2
          </span>
        </div>
        <p className="text-sm text-gray-500 mt-8">
          La home actuelle sur &quot;/&quot; reste inchangée jusqu&apos;à validation complète.
        </p>
      </div>
    </div>
  );
}
