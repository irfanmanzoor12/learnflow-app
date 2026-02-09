"use client";
import { useState } from "react";
import dynamic from "next/dynamic";

const MonacoEditor = dynamic(() => import("@monaco-editor/react"), { ssr: false });

const STARTER_CODE = `# Welcome to LearnFlow Code Runner!
# Write your Python code here and click "Run"

for i in range(5):
    print(f"Hello, iteration {i}!")
`;

export default function CodePage() {
  const [code, setCode] = useState(STARTER_CODE);
  const [output, setOutput] = useState("");
  const [running, setRunning] = useState(false);
  const [error, setError] = useState("");

  async function runCode() {
    setRunning(true);
    setOutput("");
    setError("");
    try {
      const res = await fetch("/api/run-code", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code, language: "python", timeout: 10 }),
      });
      const data = await res.json();
      if (data.stdout) setOutput(data.stdout);
      if (data.stderr) setError(data.stderr);
      if (data.error) setError(data.error);
      if (!data.stdout && !data.stderr && !data.error) setOutput("(no output)");
    } catch {
      setError("Could not reach code runner. Is the backend running?");
    }
    setRunning(false);
  }

  return (
    <div style={{ display: "flex", height: "calc(100vh - 57px)" }}>
      {/* Editor panel */}
      <div style={{ flex: 1, display: "flex", flexDirection: "column", borderRight: "1px solid #334155" }}>
        <div style={{
          display: "flex", justifyContent: "space-between", alignItems: "center",
          padding: "8px 16px", background: "#1e293b", borderBottom: "1px solid #334155"
        }}>
          <span style={{ fontWeight: 600, fontSize: 14 }}>Python Editor</span>
          <button
            onClick={runCode}
            disabled={running}
            style={{
              padding: "8px 20px", borderRadius: 6, border: "none",
              background: "#10b981", color: "white", fontWeight: 600, fontSize: 13,
              cursor: running ? "not-allowed" : "pointer", opacity: running ? 0.6 : 1,
            }}
          >
            {running ? "Running..." : "Run"}
          </button>
        </div>
        <div style={{ flex: 1 }}>
          <MonacoEditor
            height="100%"
            language="python"
            theme="vs-dark"
            value={code}
            onChange={(v) => setCode(v || "")}
            options={{
              minimap: { enabled: false },
              fontSize: 14,
              lineNumbers: "on",
              scrollBeyondLastLine: false,
              padding: { top: 12 },
            }}
          />
        </div>
      </div>

      {/* Output panel */}
      <div style={{ width: 400, display: "flex", flexDirection: "column", background: "#0c1222" }}>
        <div style={{
          padding: "8px 16px", background: "#1e293b", borderBottom: "1px solid #334155",
          fontWeight: 600, fontSize: 14
        }}>
          Output
        </div>
        <div style={{ flex: 1, padding: 16, overflow: "auto" }}>
          {output && (
            <pre style={{ margin: 0, color: "#10b981", fontFamily: "monospace", fontSize: 13, whiteSpace: "pre-wrap" }}>
              {output}
            </pre>
          )}
          {error && (
            <pre style={{ margin: output ? "12px 0 0" : 0, color: "#ef4444", fontFamily: "monospace", fontSize: 13, whiteSpace: "pre-wrap" }}>
              {error}
            </pre>
          )}
          {!output && !error && !running && (
            <p style={{ color: "#475569", fontStyle: "italic", margin: 0 }}>
              Click "Run" to execute your code
            </p>
          )}
          {running && (
            <p style={{ color: "#f59e0b", fontStyle: "italic", margin: 0 }}>
              Executing...
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
