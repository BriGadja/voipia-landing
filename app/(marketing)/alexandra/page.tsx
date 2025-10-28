import { agents } from '@/lib/data/agents';

export default function AlexandraPage() {
  const alexandra = agents.alexandra;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{alexandra.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${alexandra.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {alexandra.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {alexandra.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-green-500/10 border border-green-500/20 mt-4">
          <span className="text-green-400 font-mono text-sm">
            En construction - Phase 5
          </span>
        </div>
      </div>
    </div>
  );
}
