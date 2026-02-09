import { NextRequest, NextResponse } from "next/server";

const CODE_RUNNER_URL = process.env.CODE_RUNNER_URL || "http://code-runner.learnflow.svc.cluster.local";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const res = await fetch(`${CODE_RUNNER_URL}/execute`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    return NextResponse.json(data);
  } catch {
    return NextResponse.json(
      { error: "Cannot reach code runner", stdout: "", stderr: "Backend is not available." },
      { status: 502 }
    );
  }
}
