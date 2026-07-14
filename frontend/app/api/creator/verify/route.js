import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    const { key } = await request.json();
    const creatorKey = process.env.CREATOR_KEY;
    if (!creatorKey) return NextResponse.json({ verified: false, reason: 'Key not configured' }, { status: 400 });
    const match = key && key.toLowerCase() === creatorKey.toLowerCase();
    return NextResponse.json({ verified: match }, { status: 200 });
  } catch {
    return NextResponse.json({ verified: false }, { status: 400 });
  }
}
