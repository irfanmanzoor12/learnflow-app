"use client";
import { useEffect, useState } from "react";

interface Progress {
  module: string;
  topic: string;
  mastery: number;
}

export default function Dashboard() {
  const [progress, setProgress] = useState<Progress[]>([]);

  useEffect(() => {
    fetch("/api/progress?user_id=1")
      .then((r) => r.json())
      .then((data) => setProgress(data.progress || []))
      .catch(() =>
        setProgress([
          { module: "basics", topic: "variables", mastery: 75 },
          { module: "basics", topic: "data_types", mastery: 60 },
          { module: "loops", topic: "for_loop", mastery: 40 },
          { module: "loops", topic: "while_loop", mastery: 20 },
          { module: "data_structures", topic: "lists", mastery: 50 },
          { module: "functions", topic: "functions", mastery: 10 },
        ])
      );
  }, []);

  return (
    <div style={{ maxWidth: 900, margin: "0 auto", padding: "40px 24px" }}>
      <h1 style={{ fontSize: 32, marginBottom: 8 }}>Welcome back, Maya!</h1>
      <p style={{ color: "#94a3b8", marginBottom: 32 }}>
        Continue your Python learning journey
      </p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16, marginBottom: 40 }}>
        <Card title="Ask a Question" desc="Chat with your AI tutor" href="/chat" color="#3b82f6" />
        <Card title="Write Code" desc="Monaco editor with live execution" href="/code" color="#10b981" />
        <Card title="Curriculum" desc="6 topics from basics to functions" href="/chat" color="#8b5cf6" />
      </div>

      <h2 style={{ fontSize: 22, marginBottom: 16 }}>Your Progress</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {progress.map((p) => (
          <div key={p.topic} style={{ background: "#1e293b", borderRadius: 8, padding: "14px 20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ textTransform: "capitalize" }}>{p.topic.replace("_", " ")}</span>
              <span style={{ color: "#94a3b8" }}>{p.mastery}%</span>
            </div>
            <div style={{ background: "#334155", borderRadius: 4, height: 8 }}>
              <div
                style={{
                  background: p.mastery > 60 ? "#10b981" : p.mastery > 30 ? "#f59e0b" : "#ef4444",
                  width: `${p.mastery}%`,
                  height: 8,
                  borderRadius: 4,
                  transition: "width 0.5s",
                }}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Card({ title, desc, href, color }: { title: string; desc: string; href: string; color: string }) {
  return (
    <a
      href={href}
      style={{
        background: "#1e293b", borderRadius: 12, padding: 24, textDecoration: "none",
        color: "inherit", border: `1px solid ${color}33`, transition: "border-color 0.2s",
      }}
    >
      <h3 style={{ margin: "0 0 8px", color }}>{title}</h3>
      <p style={{ margin: 0, color: "#94a3b8", fontSize: 14 }}>{desc}</p>
    </a>
  );
}
