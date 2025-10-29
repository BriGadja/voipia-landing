import Link from 'next/link';
import { Lightbulb, ArrowRight } from 'lucide-react';

interface CrossSellHintProps {
  text: string;
  agentName: string;
  agentLink: string;
}

export function CrossSellHint({ text, agentName, agentLink }: CrossSellHintProps) {
  return (
    <Link href={agentLink}>
      <div className="group inline-flex items-start gap-3 p-4 rounded-lg bg-violet-500/10 border border-violet-500/20 hover:border-violet-500/40 hover:bg-violet-500/20 transition-all">
        <Lightbulb className="w-5 h-5 text-violet-400 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <p className="text-sm text-gray-300 group-hover:text-white transition-colors">
            {text}{' '}
            <span className="font-semibold text-violet-400 group-hover:underline">
              {agentName}
            </span>
          </p>
        </div>
        <ArrowRight className="w-5 h-5 text-violet-400 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0" />
      </div>
    </Link>
  );
}
