import { agents } from '@/lib/data/agents';

export default function ArthurPage() {
  const arthur = agents.arthur;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{arthur.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${arthur.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {arthur.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {arthur.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20 mt-4">
          <span className="text-orange-400 font-mono text-sm">
            En construction - Phase 4
          </span>
        </div>
      </div>
    </div>
  );
}
