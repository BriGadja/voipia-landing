import Link from 'next/link';
import { Lightbulb, ArrowRight } from 'lucide-react';

interface CrossSellAgent {
  text: string;
  agentName: string;
  agentLink: string;
  icon: string;
  variant: 'blue' | 'orange' | 'green'; // Louis: blue, Arthur: orange, Alexandra: green
}

interface CrossSellHintDualProps {
  leftAgent: CrossSellAgent;
  rightAgent: CrossSellAgent;
}

const variantStyles = {
  blue: {
    container: 'bg-blue-500/10 border-blue-500/20 hover:border-blue-500/40 hover:bg-blue-500/20',
    icon: 'text-blue-400',
    text: 'text-blue-400',
  },
  orange: {
    container: 'bg-orange-500/10 border-orange-500/20 hover:border-orange-500/40 hover:bg-orange-500/20',
    icon: 'text-orange-400',
    text: 'text-orange-400',
  },
  green: {
    container: 'bg-green-500/10 border-green-500/20 hover:border-green-500/40 hover:bg-green-500/20',
    icon: 'text-green-400',
    text: 'text-green-400',
  },
};

export function CrossSellHintDual({ leftAgent, rightAgent }: CrossSellHintDualProps) {
  const leftStyles = variantStyles[leftAgent.variant];
  const rightStyles = variantStyles[rightAgent.variant];

  return (
    <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto">
      {/* Left Agent */}
      <Link href={leftAgent.agentLink} className="block">
        <div className={`group flex items-center gap-4 p-6 rounded-lg border transition-all h-full ${leftStyles.container}`}>
          <Lightbulb className={`w-6 h-6 flex-shrink-0 ${leftStyles.icon}`} />
          <div className="flex-1">
            <p className="text-base text-gray-300 group-hover:text-white transition-colors">
              {leftAgent.text}{' '}
              <span className={`font-semibold group-hover:underline ${leftStyles.text}`}>
                {leftAgent.icon} {leftAgent.agentName}
              </span>
            </p>
          </div>
          <ArrowRight className={`w-6 h-6 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0 ${leftStyles.icon}`} />
        </div>
      </Link>

      {/* Right Agent */}
      <Link href={rightAgent.agentLink} className="block">
        <div className={`group flex items-center gap-4 p-6 rounded-lg border transition-all h-full ${rightStyles.container}`}>
          <Lightbulb className={`w-6 h-6 flex-shrink-0 ${rightStyles.icon}`} />
          <div className="flex-1">
            <p className="text-base text-gray-300 group-hover:text-white transition-colors">
              {rightAgent.text}{' '}
              <span className={`font-semibold group-hover:underline ${rightStyles.text}`}>
                {rightAgent.icon} {rightAgent.agentName}
              </span>
            </p>
          </div>
          <ArrowRight className={`w-6 h-6 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0 ${rightStyles.icon}`} />
        </div>
      </Link>
    </div>
  );
}
