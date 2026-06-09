/**
 * canlifal.com Next.js (App Router) — kopyala-yapıştır referansı
 *
 * Hedef: app/api/music/search/route.ts
 *
 * Ortam:
 *   YOUTUBE_API_KEY=AIza...
 *   JWT_ACCESS_SECRET=...  (mobil Bearer doğrulama)
 *
 * İstek:
 *   GET /api/music/search?q=Bülent+Ersoy
 *   Authorization: Bearer <mobil JWT>
 * Yanıt:
 *   { "items": [{ videoId, title, thumbnail, channelTitle, duration }] }
 */

import { NextRequest, NextResponse } from "next/server";
import { requireApiAuth } from "@/lib/verifyApiAuth";
import {
  searchMusicViaYoutubeApi,
  YoutubeApiNotConfiguredError,
} from "@/lib/youtubeMusicSearch";

export async function GET(request: NextRequest) {
  const auth = await requireApiAuth(request);
  if (!auth) {
    return NextResponse.json(
      { error: "Oturum açmanız gerekiyor" },
      { status: 401 },
    );
  }

  const q =
    request.nextUrl.searchParams.get("q")?.trim() ??
    request.nextUrl.searchParams.get("query")?.trim() ??
    "";
  if (q.length < 2) {
    return NextResponse.json(
      { error: "Arama en az 2 karakter olmalı" },
      { status: 400 },
    );
  }

  try {
    const items = await searchMusicViaYoutubeApi(q);
    return NextResponse.json({ items });
  } catch (e) {
    if (e instanceof YoutubeApiNotConfiguredError) {
      return NextResponse.json(
        {
          error:
            "YOUTUBE_API_KEY sunucuda tanımlı değil. Yönetici panelinden ekleyin.",
        },
        { status: 503 },
      );
    }
    const msg = e instanceof Error ? e.message : "YouTube araması başarısız";
    return NextResponse.json({ error: msg }, { status: 502 });
  }
}
