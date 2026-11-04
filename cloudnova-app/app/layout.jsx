import "./globals.css";

export const metadata = {
  title: "StratusForge Systems — Private Cloud Platform",
  description: "Hardened multi-tier private-cloud platform",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
