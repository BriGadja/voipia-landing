'use client';

import { KPICard } from '@/components/dashboard/KPICard';
import type { LeasingMetrics } from '@/lib/types/financial';

interface LeasingKPIGridProps {
  data: LeasingMetrics | undefined;
  isLoading: boolean;
}

/**
 * LeasingKPIGrid Component
 *
 * Displays 4 KPI cards specific to leasing revenue model:
 * - Total Leasing Revenue: Total subscription revenue (100% margin)
 * - Clients with Leasing: Number of clients using leasing model
 * - Average Revenue per Client: Avg monthly leasing fee per client
 * - MRR: Monthly Recurring Revenue
 *
 * Colors: Violet/Purple theme for leasing (matches FinancialViewToggle)
 */
export function LeasingKPIGrid({ data, isLoading }: LeasingKPIGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {Array.from({ length: 4 }).map((_, i) => (
          <div
            key={i}
            className="h-32 rounded-xl bg-white/5 border border-white/10 animate-pulse"
          />
        ))}
      </div>
    );
  }

  if (!data) {
    return (
      <div className="text-center text-white/60 py-12">
        Aucune donnée de leasing disponible pour la période sélectionnée
      </div>
    );
  }

  const leasingKPIs = [
    {
      label: '💰 Revenu Leasing Total',
      value: data.total_leasing_revenue,
      format: 'currency' as const,
      decorationColor: 'violet' as const,
    },
    {
      label: '👥 Clients avec Leasing',
      value: data.leasing_client_count,
      format: 'number' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: '📊 Revenu Moyen/Client',
      value: data.avg_leasing_per_client,
      format: 'currency' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: '📈 MRR',
      value: data.mrr,
      format: 'currency' as const,
      decorationColor: 'violet' as const,
    },
  ];

  return (
    <div className="space-y-4">
      {/* Badge: 100% Margin */}
      <div className="flex items-center gap-2">
        <div className="px-3 py-1 bg-violet-500/20 border border-violet-500/30 rounded-full">
          <span className="text-sm font-medium text-violet-300">
            💎 Marge 100% - Revenu fixe mensuel
          </span>
        </div>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {leasingKPIs.map((kpi, index) => (
          <KPICard
            key={kpi.label}
            label={kpi.label}
            value={kpi.value}
            format={kpi.format}
            decorationColor={kpi.decorationColor}
            delay={index * 0.05}
          />
        ))}
      </div>

      {/* Additional Info */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Taux d&#39;adoption</p>
          <p className="text-lg font-semibold text-white">
            {data.leasing_adoption_rate.toFixed(1)}%
          </p>
        </div>
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Agents en leasing</p>
          <p className="text-lg font-semibold text-white">
            {data.active_leasing_count}
          </p>
        </div>
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Leasing moyen mensuel</p>
          <p className="text-lg font-semibold text-white">
            {data.avg_monthly_leasing.toFixed(2)}€
          </p>
        </div>
      </div>
    </div>
  );
}
