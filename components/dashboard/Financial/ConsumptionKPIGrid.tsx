'use client';

import { KPICard } from '@/components/dashboard/KPICard';
import type { ConsumptionMetrics } from '@/lib/types/financial';

interface ConsumptionKPIGridProps {
  data: ConsumptionMetrics | undefined;
  isLoading: boolean;
}

/**
 * ConsumptionKPIGrid Component
 *
 * Displays 6 KPI cards specific to consumption (usage-based) revenue model:
 * - Revenue: Total consumption revenue (calls + SMS + emails)
 * - Margin: Total consumption margin (revenue - provider costs)
 * - Margin %: Margin percentage on consumption
 * - Provider Costs: Total costs from providers (STT, TTS, LLM, telecom, SMS, emails)
 * - Total Volume: Sum of all usage (calls + SMS + emails)
 * - Avg Cost per Unit: Average cost across all channels
 *
 * Colors: Cyan/Blue theme for consumption (matches FinancialViewToggle)
 */
export function ConsumptionKPIGrid({ data, isLoading }: ConsumptionKPIGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {Array.from({ length: 6 }).map((_, i) => (
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
        Aucune donnée de consommation disponible pour la période sélectionnée
      </div>
    );
  }

  // Calculate total volume and average cost per unit
  const totalVolume = data.total_calls + data.total_sms + data.total_emails;
  const avgCostPerUnit = totalVolume > 0
    ? data.total_provider_cost / totalVolume
    : 0;

  const consumptionKPIs = [
    {
      label: '💵 Revenu Consommation',
      value: data.total_consumption_revenue,
      format: 'currency' as const,
      decorationColor: 'blue' as const,
    },
    {
      label: '💎 Marge Consommation',
      value: data.total_consumption_margin,
      format: 'currency' as const,
      decorationColor: 'emerald' as const,
    },
    {
      label: '📊 Marge % Consommation',
      value: data.consumption_margin_pct,
      format: 'percentage' as const,
      decorationColor: 'violet' as const,
    },
    {
      label: '💸 Coûts Provider',
      value: data.total_provider_cost,
      format: 'currency' as const,
      decorationColor: 'red' as const,
    },
    {
      label: '📞 Volume Total',
      value: totalVolume,
      format: 'number' as const,
      decorationColor: 'teal' as const,
    },
    {
      label: '💲 Coût Moyen/Unité',
      value: avgCostPerUnit,
      format: 'currency' as const,
      decorationColor: 'amber' as const,
    },
  ];

  return (
    <div className="space-y-4">
      {/* Badge: Variable Margin */}
      <div className="flex items-center gap-2">
        <div className="px-3 py-1 bg-cyan-500/20 border border-cyan-500/30 rounded-full">
          <span className="text-sm font-medium text-cyan-300">
            📈 Marge variable - Paiement à l'usage
          </span>
        </div>
      </div>

      {/* Main KPI Grid - 2 rows of 3 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {consumptionKPIs.map((kpi, index) => (
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

      {/* Channel Breakdown - 3 columns */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
        {/* Calls Channel */}
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg space-y-2">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-xl">📞</span>
            <h4 className="text-sm font-semibold text-white">Appels</h4>
          </div>
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Volume</span>
              <span className="text-white font-medium">{data.total_calls.toLocaleString('fr-FR')}</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Revenu</span>
              <span className="text-white font-medium">{data.call_revenue.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Coût</span>
              <span className="text-red-400 font-medium">{data.call_provider_cost.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Marge</span>
              <span className="text-emerald-400 font-medium">{data.call_margin.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs pt-1 border-t border-white/10">
              <span className="text-white/50">Marge %</span>
              <span className="text-violet-400 font-semibold">{data.call_margin_pct.toFixed(1)}%</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Prix/min</span>
              <span className="text-white font-medium">{data.avg_revenue_per_minute.toFixed(4)}€</span>
            </div>
          </div>
        </div>

        {/* SMS Channel */}
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg space-y-2">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-xl">💬</span>
            <h4 className="text-sm font-semibold text-white">SMS</h4>
          </div>
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Volume</span>
              <span className="text-white font-medium">{data.total_sms.toLocaleString('fr-FR')}</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Revenu</span>
              <span className="text-white font-medium">{data.sms_revenue.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Coût</span>
              <span className="text-red-400 font-medium">{data.sms_provider_cost.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Marge</span>
              <span className="text-emerald-400 font-medium">{data.sms_margin.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs pt-1 border-t border-white/10">
              <span className="text-white/50">Marge %</span>
              <span className="text-violet-400 font-semibold">{data.sms_margin_pct.toFixed(1)}%</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Prix/SMS</span>
              <span className="text-white font-medium">{data.avg_revenue_per_sms.toFixed(4)}€</span>
            </div>
          </div>
        </div>

        {/* Email Channel */}
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg space-y-2">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-xl">📧</span>
            <h4 className="text-sm font-semibold text-white">Emails</h4>
          </div>
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Volume</span>
              <span className="text-white font-medium">{data.total_emails.toLocaleString('fr-FR')}</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Revenu</span>
              <span className="text-white font-medium">{data.email_revenue.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Coût</span>
              <span className="text-red-400 font-medium">{data.email_provider_cost.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Marge</span>
              <span className="text-emerald-400 font-medium">{data.email_margin.toFixed(2)}€</span>
            </div>
            <div className="flex justify-between text-xs pt-1 border-t border-white/10">
              <span className="text-white/50">Marge %</span>
              <span className="text-violet-400 font-semibold">{data.email_margin_pct.toFixed(1)}%</span>
            </div>
            <div className="flex justify-between text-xs">
              <span className="text-white/50">Prix/email</span>
              <span className="text-white font-medium">{data.avg_revenue_per_email.toFixed(4)}€</span>
            </div>
          </div>
        </div>
      </div>

      {/* Business Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Clients actifs</p>
          <p className="text-lg font-semibold text-white">
            {data.consumption_client_count}
          </p>
        </div>
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Agents en consommation</p>
          <p className="text-lg font-semibold text-white">
            {data.active_deployment_count}
          </p>
        </div>
        <div className="p-4 bg-slate-900/50 border border-slate-700/50 rounded-lg">
          <p className="text-xs text-white/50 mb-1">Consommation moy./client</p>
          <p className="text-lg font-semibold text-white">
            {data.avg_consumption_per_client.toFixed(2)}€
          </p>
        </div>
      </div>
    </div>
  );
}
