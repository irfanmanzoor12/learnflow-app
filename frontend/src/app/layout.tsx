import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "LearnFlow - AI Python Tutor",
  description: "AI-powered Python tutoring platform",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif", background: "#0f172a", color: "#e2e8f0" }}>
        <nav style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "12px 24px", background: "#1e293b", borderBottom: "1px solid #334155"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <span style={{ fontSize: "24px" }}>&#x1F4DA;</span>
            <span style={{ fontSize: "20px", fontWeight: 700 }}>LearnFlow</span>
          </div>
          <div style={{ display: "flex", gap: "24px" }}>
            <a href="/" style={{ color: "#94a3b8", textDecoration: "none" }}>Dashboard</a>
            <a href="/chat" style={{ color: "#94a3b8", textDecoration: "none" }}>Chat</a>
            <a href="/code" style={{ color: "#94a3b8", textDecoration: "none" }}>Code</a>
          </div>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
