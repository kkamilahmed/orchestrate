import type { Metadata, Viewport } from 'next';
import './app.css';

export const metadata: Metadata = {
  title: 'AI Assistant',
  description: 'An AI assistant that notices what matters, drafts the busywork, and keeps you in control.',
  icons: {
    icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' fill='%230f62fe'/%3E%3Cpath fill='%23fff' d='M9 22V10h3l4 7 4-7h3v12h-3v-7l-4 7-4-7v7z'/%3E%3C/svg%3E",
  },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1 };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="cds--white">
      <head>
        {/* Carbon Design System v11 compiled styles + IBM Plex fonts, served from public/ so the demo
            needs no CDN on stage. Imported into a cascade layer so the unlayered app.css overrides always
            win, whatever order Next.js emits the stylesheets in. */}
        <style>{`@import url('/carbon/carbon.min.css') layer(carbon);`}</style>
      </head>
      <body>{children}</body>
    </html>
  );
}
