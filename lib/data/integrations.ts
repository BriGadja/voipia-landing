import { IntegrationLogo } from '@/lib/types/landing';

export const integrations: IntegrationLogo[] = [
  // CRM
  { name: 'Pipedrive', logo: '/logos/pipedrive.svg', category: 'crm' },
  { name: 'HubSpot', logo: '/logos/hubspot.svg', category: 'crm' },
  { name: 'Salesforce', logo: '/logos/salesforce.svg', category: 'crm' },

  // Calendar
  { name: 'Google Calendar', logo: '/logos/google-calendar.svg', category: 'calendar' },
  { name: 'Outlook', logo: '/logos/outlook.svg', category: 'calendar' },
  { name: 'Calendly', logo: '/logos/calendly.svg', category: 'calendar' },

  // Automation
  { name: 'Make', logo: '/logos/make.svg', category: 'automation' },
  { name: 'Zapier', logo: '/logos/zapier.svg', category: 'automation' },
  { name: 'n8n', logo: '/logos/n8n.svg', category: 'automation' },

  // AI
  { name: 'Eleven Labs', logo: '/logos/elevenlabs.svg', category: 'ai' },
  { name: 'Cartesia', logo: '/logos/cartesia.svg', category: 'ai' },
  { name: 'Mistral AI', logo: '/logos/mistral.svg', category: 'ai' },
  { name: 'Claude', logo: '/logos/claude.svg', category: 'ai' },
  { name: 'OpenAI', logo: '/logos/openai.svg', category: 'ai' },
];

export const getIntegrationsByCategory = (category: string): IntegrationLogo[] => {
  return integrations.filter(integration => integration.category === category);
};
