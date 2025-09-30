'use client'

import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import Button from '@/components/ui/Button'
import { Menu, X, ChevronDown, Calculator } from 'lucide-react'
import Link from 'next/link'

export default function Navigation() {
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null)

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const navItems = [
    { label: 'Nos Agents', href: '#agents', hasDropdown: true },
    { label: 'Comment ça marche', href: '#how-it-works' },
    { label: 'Métriques', href: '#metrics' },
    { label: 'ROI', href: '#roi-calculator' },
    { label: 'Démo', href: '#demo' }
  ]

  const agentLinks = [
    { label: 'Louis - Rappels & RDV', href: '/agents/louis' },
    { label: 'Arthur - Prospection', href: '/agents/arthur' }
  ]

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.5 }}
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled 
          ? 'bg-black/20 backdrop-blur-xl border-b border-white/10' 
          : ''
      }`}
    >
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          <motion.div 
            className="text-2xl font-bold text-white"
            whileHover={{ scale: 1.05 }}
          >
            <span className="text-gradient">Voipia</span>
          </motion.div>

          <div className="hidden md:flex items-center gap-8">
            {navItems.map((item, index) => (
              <div key={item.label} className="relative">
                {item.hasDropdown ? (
                  <div
                    onMouseEnter={() => setActiveDropdown(item.label)}
                    onMouseLeave={() => setActiveDropdown(null)}
                    className="relative"
                  >
                    <motion.a
                      href={item.href}
                      className="flex items-center gap-1 text-white/80 hover:text-white transition-colors"
                      initial={{ opacity: 0, y: -20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.1 }}
                      whileHover={{ y: -2 }}
                    >
                      {item.label}
                      <ChevronDown className="w-4 h-4" />
                    </motion.a>

                    <AnimatePresence>
                      {activeDropdown === item.label && (
                        <motion.div
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: 10 }}
                          transition={{ duration: 0.2 }}
                          className="absolute top-full left-0 mt-2 w-56 bg-black/90 backdrop-blur-xl border border-white/20 rounded-xl shadow-xl z-50"
                        >
                          {agentLinks.map((link, linkIndex) => (
                            <Link
                              key={link.href}
                              href={link.href}
                              className="block px-4 py-3 text-white/80 hover:text-white hover:bg-white/10 transition-colors first:rounded-t-xl last:rounded-b-xl"
                            >
                              {link.label}
                            </Link>
                          ))}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                ) : (
                  <motion.a
                    href={item.href}
                    className="text-white/80 hover:text-white transition-colors"
                    initial={{ opacity: 0, y: -20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                    whileHover={{ y: -2 }}
                  >
                    {item.label}
                  </motion.a>
                )}
              </div>
            ))}
          </div>

          <div className="hidden md:flex items-center gap-4">
            <Button
              variant="secondary"
              size="sm"
              onClick={() => {
                const element = document.getElementById('roi-calculator')
                element?.scrollIntoView({ behavior: 'smooth' })
              }}
            >
              <Calculator className="w-4 h-4 mr-2" />
              Calculer mon ROI
            </Button>
            <Button
              size="sm"
              onClick={() => window.open('https://forms.fillout.com/t/nU9QEqNRRRus', '_blank')}
            >
              Essayer gratuitement
            </Button>
          </div>

          <button
            className="md:hidden text-white p-2"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          >
            {isMobileMenuOpen ? <X /> : <Menu />}
          </button>
        </div>
      </div>

      <AnimatePresence>
        {isMobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.3 }}
            className="md:hidden bg-black/95 backdrop-blur-xl border-t border-white/10"
          >
            <div className="container mx-auto px-4 py-4">
              {navItems.map((item, index) => (
                <div key={item.label}>
                  <motion.a
                    href={item.href}
                    className="block py-3 text-white/80 hover:text-white transition-colors"
                    onClick={() => setIsMobileMenuOpen(false)}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.05 }}
                  >
                    {item.label}
                  </motion.a>
                  {item.hasDropdown && (
                    <div className="ml-4 space-y-2">
                      {agentLinks.map((link, linkIndex) => (
                        <Link
                          key={link.href}
                          href={link.href}
                          className="block py-2 text-sm text-white/60 hover:text-white transition-colors"
                          onClick={() => setIsMobileMenuOpen(false)}
                        >
                          {link.label}
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              ))}
              <div className="flex flex-col gap-2 pt-4 border-t border-white/10 mt-4">
                <Button
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  onClick={() => {
                    const element = document.getElementById('roi-calculator')
                    element?.scrollIntoView({ behavior: 'smooth' })
                    setIsMobileMenuOpen(false)
                  }}
                >
                  <Calculator className="w-4 h-4 mr-2" />
                  Calculer mon ROI
                </Button>
                <Button
                  size="sm"
                  className="w-full"
                  onClick={() => window.open('https://forms.fillout.com/t/nU9QEqNRRRus', '_blank')}
                >
                  Essayer gratuitement
                </Button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.nav>
  )
}