import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // Removed experimental.ppr as it requires Next.js canary
  poweredByHeader: false,
  compress: true,
  images: {
    formats: ['image/webp', 'image/avif'],
    minimumCacheTTL: 60,
  },
}

export default nextConfig