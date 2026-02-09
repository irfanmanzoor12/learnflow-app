import { NextRequest, NextResponse } from "next/server";

const TRIAGE_URL = process.env.TRIAGE_URL || "http://triage-agent.learnflow.svc.cluster.local";

export async function GET(req: NextRequest) {
  const userId = req.nextUrl.searchParams.get("user_id") || "1";
  try {
    const res = await fetch(`${TRIAGE_URL}/progress/${userId}`);
    const data = await res.json();
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ progress: [] }, { status: 502 });
  }
}
