import type { Metadata, Viewport } from "next";
import Nav from "@/components/Nav";
import "./globals.css";

export const metadata: Metadata = {
  title: "Studio TikTok — Dashboard",
  description: "لوحة تحكّم ستوديو التيكتوك: استعمال الـAPI + مولّد السكريبتات",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700;800&family=Tajawal:wght@400;500;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <div className="wrap">
          <header className="topbar">
            <div className="brand">
              <span className="logo">🎬</span>
              <div>
                <h1>ستوديو التيكتوك</h1>
                <div className="sub">لوحة التحكّم · API + مولّد</div>
              </div>
            </div>
            <Nav />
          </header>
          {children}
        </div>
      </body>
    </html>
  );
}
