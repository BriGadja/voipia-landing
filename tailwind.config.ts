import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: 'class',
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  safelist: [
    'from-blue-500',
    'to-blue-600',
    'from-arthur',
    'to-orange-600',
    'from-alexandra', 
    'to-green-600',
    'text-louis',
    'text-arthur',
    'text-alexandra',
    // Chatbot classes
    'voipia-chatbot-trigger',
    'voipia-chatbot-window',
    'voipia-chatbot-header',
    'voipia-chatbot-messages',
    'voipia-chatbot-input',
    'voipia-chatbot-message',
    'voipia-chatbot-widget'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#6B46C1',
          dark: '#5a3aa2',
        },
        secondary: {
          DEFAULT: '#3B82F6',
          dark: '#2563eb',
        },
        louis: '#3B82F6',
        arthur: '#FB923C',
        alexandra: '#10B981',
      },
      fontFamily: {
        inter: ['var(--font-inter)'],
      },
      animation: {
        'fade-in': 'fadeIn 0.8s ease-out',
        'fade-in-up': 'fadeInUp 0.8s ease-out',
        'scale-in': 'scaleIn 0.5s ease-out',
        'breathing': 'breathing 3s ease-in-out infinite',
        'glow': 'glow 2s ease-in-out infinite',
        'counter': 'counter 2s ease-out',
        'wave': 'wave 1.5s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(50px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        breathing: {
          '0%, 100%': { transform: 'scale(1)' },
          '50%': { transform: 'scale(1.05)' },
        },
        glow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(107, 70, 193, 0.5)' },
          '50%': { boxShadow: '0 0 40px rgba(107, 70, 193, 0.8)' },
        },
        counter: {
          '0%': { transform: 'translateY(100%)' },
          '100%': { transform: 'translateY(0)' },
        },
        wave: {
          '0%, 100%': { transform: 'scaleY(1)' },
          '50%': { transform: 'scaleY(1.5)' },
        },
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic': 'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
    },
  },
  plugins: [],
}
export default config