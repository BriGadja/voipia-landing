// Invoice Types - Monthly Billing Dashboard
// Types pour le tableau de facturation mensuel
// SÉCURITÉ: Admin only - contient les données de tarification

/**
 * Ligne de facturation individuelle
 */
export interface InvoiceLine {
  type: 'leasing' | 'calls' | 'sms' | 'emails'
  description: string
  quantity: number
  unit: string
  unit_price: number
  amount: number
}

/**
 * Facturation par déploiement d'agent
 */
export interface DeploymentInvoice {
  deployment_id: string
  deployment_name: string
  agent_type: string
  deployed_at: string
  is_first_month: boolean
  prorata_days: number
  total_days_in_month: number
  lines: InvoiceLine[]
  subtotal: number
}

/**
 * Facturation par client
 */
export interface ClientInvoice {
  client_id: string
  client_name: string
  deployments: DeploymentInvoice[]
  total_leasing: number
  total_consumption: number
  total_client: number
}

/**
 * Période de facturation
 */
export interface InvoicePeriod {
  year: number
  month: number
  label: string
  start_date: string
  end_date: string
  days_in_month: number
}

/**
 * Résumé global de facturation
 */
export interface InvoiceSummary {
  total_leasing: number
  total_consumption: number
  total_invoice: number
  total_clients: number
}

/**
 * Réponse complète de get_monthly_invoice_summary()
 */
export interface MonthlyInvoiceSummaryResponse {
  period: InvoicePeriod
  summary: InvoiceSummary
  clients: ClientInvoice[]
}

/**
 * Props pour le sélecteur de mois
 */
export interface MonthSelectorProps {
  selectedYear: number
  selectedMonth: number
  onChange: (year: number, month: number) => void
  minDate?: Date
  maxDate?: Date
  disabled?: boolean
}

/**
 * Props pour le tableau de facturation
 */
export interface InvoiceSummaryTableProps {
  data: MonthlyInvoiceSummaryResponse | null | undefined
  isLoading: boolean
  error?: Error | null
}

/**
 * État du mois sélectionné
 */
export interface SelectedMonth {
  year: number
  month: number
}

/**
 * Utilitaire pour formater les montants
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

/**
 * Utilitaire pour formater les quantités
 */
export function formatQuantity(quantity: number, unit: string): string {
  const formattedQty = new Intl.NumberFormat('fr-FR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(quantity)
  return `${formattedQty} ${unit}`
}

/**
 * Obtenir le label du mois en français
 */
export function getMonthLabel(year: number, month: number): string {
  const date = new Date(year, month - 1, 1)
  return date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })
}

/**
 * Obtenir le mois précédent
 */
export function getPreviousMonth(year: number, month: number): SelectedMonth {
  if (month === 1) {
    return { year: year - 1, month: 12 }
  }
  return { year, month: month - 1 }
}

/**
 * Obtenir le mois suivant
 */
export function getNextMonth(year: number, month: number): SelectedMonth {
  if (month === 12) {
    return { year: year + 1, month: 1 }
  }
  return { year, month: month + 1 }
}

/**
 * Vérifier si un mois est dans le futur
 */
export function isFutureMonth(year: number, month: number): boolean {
  const now = new Date()
  const currentYear = now.getFullYear()
  const currentMonth = now.getMonth() + 1

  if (year > currentYear) return true
  if (year === currentYear && month > currentMonth) return true
  return false
}

/**
 * Obtenir les dates par défaut (mois précédent)
 */
export function getDefaultInvoiceMonth(): SelectedMonth {
  const now = new Date()
  return getPreviousMonth(now.getFullYear(), now.getMonth() + 1)
}
