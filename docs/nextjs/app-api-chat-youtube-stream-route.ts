/**
 * canlifal.com Next.js — YouTube ses akışı çözümleyici
 *
 * Hedef: app/api/chat/youtube-stream/route.ts
 *
 * Flutter: YoutubeStreamResolver._resolveViaSiteApi
 * Web: sesli oda DJ kuyruğu başlatırken Piped üzerinden stream URL
 *
 * İstek:
 *   GET /api/chat/youtube-stream?url=https://youtube.com/watch?v=...
 *   veya ?videoId=dQw4w9WgXcQ
 *
 * Yanıt:
 *   { "streamUrl": "https://...", "url": "https://..." }
 */

import { NextRequest, NextResponse } from "next/server";
import { resolveYoutubeStreamUrl } from "@/lib/resolveYoutubeStream";

export async function GET(request: NextRequest) {
  const url =
    request.nextUrl.searchParams.get("url")?.trim() ??
    request.nextUrl.searchParams.get("videoId")?.trim() ??
    "";

  if (!url) {
    return NextResponse.json(
      { error: "url veya videoId gerekli" },
      { status: 400 },
    );
  }

  const streamUrl = await resolveYoutubeStreamUrl(url);
  if (!streamUrl) {
    return NextResponse.json(
      { error: "Ses akışı bulunamadı" },
      { status: 404 },
    );
  }

  return NextResponse.json({ streamUrl, url: streamUrl });
}
