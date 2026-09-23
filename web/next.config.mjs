import { fileURLToPath } from 'node:url';

/** @type {import('next').NextConfig} */
const API_URL = process.env.API_URL || 'http://localhost:3001';

const nextConfig = {
  // This app lives in a subfolder of the repo; keep Next from treating the parent as the root.
  turbopack: { root: fileURLToPath(new URL('.', import.meta.url)) },
  reactStrictMode: true,
  // Streaming responses (SSE) must not be gzipped by the proxy, or tokens arrive in bursts.
  compress: false,
  async rewrites() {
    // The browser only ever talks to Next.js; /api/* is proxied to the Node API server,
    // which holds the OpenRouter key and the database connection.
    return [{ source: '/api/:path*', destination: `${API_URL}/api/:path*` }];
  },
};

export default nextConfig;
