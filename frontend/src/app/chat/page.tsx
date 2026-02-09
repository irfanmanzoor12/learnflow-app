"use client";
import { useState, useRef, useEffect } from "react";

interface Message {
  role: "user" | "assistant";
  content: string;
  agent?: string;
  intent?: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([
    { role: "assistant", content: "Hi Maya! I'm your Python tutor. Ask me anything about Python — loops, variables, lists, functions, and more!" },
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send() {
    if (!input.trim() || loading) return;
    const userMsg = input.trim();
    setInput("");
    setMessages((m) => [...m, { role: "user", content: userMsg }]);
    setLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: userMsg, user_id: 1 }),
      });
      const data = await res.json();
      setMessages((m) => [
        ...m,
        { role: "assistant", content: data.response || data.error || "No response", agent: data.agent, intent: data.intent },
      ]);
    } catch {
      setMessages((m) => [...m, { role: "assistant", content: "Could not reach the tutor. Is the backend running?" }]);
    }
    setLoading(false);
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "calc(100vh - 57px)" }}>
      <div style={{ flex: 1, overflow: "auto", padding: "24px", maxWidth: 800, margin: "0 auto", width: "100%" }}>
        {messages.map((m, i) => (
          <div key={i} style={{ display: "flex", justifyContent: m.role === "user" ? "flex-end" : "flex-start", marginBottom: 16 }}>
            <div
              style={{
                maxWidth: "75%",
                padding: "12px 16px",
                borderRadius: 12,
                background: m.role === "user" ? "#3b82f6" : "#1e293b",
                whiteSpace: "pre-wrap",
                lineHeight: 1.6,
                fontSize: 15,
              }}
            >
              {m.agent && (
                <div style={{ fontSize: 11, color: "#94a3b8", marginBottom: 4 }}>
                  {m.agent} {m.intent ? `(${m.intent})` : ""}
                </div>
              )}
              {m.content}
            </div>
          </div>
        ))}
        {loading && (
          <div style={{ color: "#94a3b8", fontStyle: "italic" }}>Thinking...</div>
        )}
        <div ref={endRef} />
      </div>

      <div style={{ padding: "16px 24px", borderTop: "1px solid #334155", background: "#1e293b" }}>
        <div style={{ display: "flex", gap: 12, maxWidth: 800, margin: "0 auto" }}>
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send()}
            placeholder="Ask about Python... (e.g. explain for loops)"
            style={{
              flex: 1, padding: "12px 16px", borderRadius: 8,
              border: "1px solid #334155", background: "#0f172a", color: "#e2e8f0",
              fontSize: 15, outline: "none",
            }}
          />
          <button
            onClick={send}
            disabled={loading}
            style={{
              padding: "12px 24px", borderRadius: 8, border: "none",
              background: "#3b82f6", color: "white", fontWeight: 600,
              cursor: loading ? "not-allowed" : "pointer", opacity: loading ? 0.6 : 1,
            }}
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}
