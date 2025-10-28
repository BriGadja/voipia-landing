import { agents } from '@/lib/data/agents';

export default function LouisPage() {
  const louis = agents.louis;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{louis.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${louis.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {louis.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {louis.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-500/10 border border-blue-500/20 mt-4">
          <span className="text-blue-400 font-mono text-sm">
            En construction - Phase 3
          </span>
        </div>
      </div>
    </div>
  );
}
