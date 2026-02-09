import { NextRequest, NextResponse } from "next/server";

const TRIAGE_URL = process.env.TRIAGE_URL || "http://triage-agent.learnflow.svc.cluster.local";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const res = await fetch(`${TRIAGE_URL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    return NextResponse.json(data);
  } catch {
    return NextResponse.json(
      { error: "Cannot reach triage agent", response: "Backend is not available. Please ensure services are running." },
      { status: 502 }
    );
  }
}
