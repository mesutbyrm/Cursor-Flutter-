import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Jeton Yükle — CanlıFal',
  description: 'WhatsApp, Papara ve Havale ile jeton yükleme',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr">
      <body>{children}</body>
    </html>
  );
}
