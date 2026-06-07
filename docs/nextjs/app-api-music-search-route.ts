/**
 * canlifal.com Next.js (App Router) — kopyala-yapıştır referansı
 *
 * Hedef dosya (canlifal web reposunda):
 *   app/api/music/search/route.ts
 *
 * Ortam değişkeni (.env / Vercel):
 *   YOUTUBE_API_KEY=AIza...
 *
 * Web istemcisi ve Flutter aynı JSON bekler:
 *   GET /api/music/search?q=Bülent+Ersoy
 *   Authorization: Bearer <JWT>
 *   → { "items": [{ videoId, title, thumbnail, channelTitle, duration }] }
 */

import { NextRequest, NextResponse } from "next/server";

type MusicSearchItem = {
  videoId: string;
  title: string;
  thumbnail: string;
  channelTitle: string;
  duration: string;
};

function formatIso8601Duration(iso?: string | null): string {
  if (!iso?.startsWith("PT")) return "";
  const m = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!m) return "";
  const total =
    Number(m[1] ?? 0) * 3600 + Number(m[2] ?? 0) * 60 + Number(m[3] ?? 0);
  if (total <= 0) return "";
  const mm = Math.floor(total / 60);
  const ss = total % 60;
  return `${mm}:${ss.toString().padStart(2, "0")}`;
}

async function verifyJwt(request: NextRequest): Promise<string | null> {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) return null;
  const token = header.slice(7).trim();
  if (!token) return null;
  // TODO: mevcut web oturum doğrulamanızı kullanın (ör. jwt.verify veya getServerSession)
  return token;
}

async function fetchDurations(apiKey: string, ids: string[]) {
  const map = new Map<string, string>();
  if (!ids.length) return map;
  const url = new URL("https://www.googleapis.com/youtube/v3/videos");
  url.searchParams.set("part", "contentDetails");
  url.searchParams.set("id", ids.join(","));
  url.searchParams.set("key", apiKey);
  const res = await fetch(url);
  if (!res.ok) return map;
  const data = (await res.json()) as {
    items?: Array<{ id?: string; contentDetails?: { duration?: string } }>;
  };
  for (const row of data.items ?? []) {
    if (row.id) {
      map.set(row.id, formatIso8601Duration(row.contentDetails?.duration));
    }
  }
  return map;
}

export async function GET(request: NextRequest) {
  const userId = await verifyJwt(request);
  if (!userId) {
    return NextResponse.json(
      { error: "Oturum açmanız gerekiyor" },
      { status: 401 },
    );
  }

  const apiKey = process.env.YOUTUBE_API_KEY?.trim();
  if (!apiKey) {
    return NextResponse.json(
      {
        error:
          "YOUTUBE_API_KEY sunucuda tanımlı değil. Yönetici panelinden ekleyin.",
      },
      { status: 503 },
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

  const searchUrl = new URL("https://www.googleapis.com/youtube/v3/search");
  searchUrl.searchParams.set("part", "snippet");
  searchUrl.searchParams.set("type", "video");
  searchUrl.searchParams.set("maxResults", "12");
  searchUrl.searchParams.set("q", q);
  searchUrl.searchParams.set("key", apiKey);

  const searchRes = await fetch(searchUrl);
  if (!searchRes.ok) {
    return NextResponse.json(
      { error: "YouTube araması başarısız" },
      { status: 502 },
    );
  }

  const searchData = (await searchRes.json()) as {
    items?: Array<{
      id?: { videoId?: string };
      snippet?: {
        title?: string;
        channelTitle?: string;
        thumbnails?: { medium?: { url?: string }; default?: { url?: string } };
      };
    }>;
  };

  const partial: Omit<MusicSearchItem, "duration">[] = [];
  for (const row of searchData.items ?? []) {
    const videoId = row.id?.videoId?.trim() ?? "";
    if (videoId.length < 6) continue;
    const sn = row.snippet;
    partial.push({
      videoId,
      title: sn?.title?.trim() || "Video",
      thumbnail:
        sn?.thumbnails?.medium?.url ??
        sn?.thumbnails?.default?.url ??
        `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
      channelTitle: sn?.channelTitle?.trim() || "",
    });
  }

  const durations = await fetchDurations(
    apiKey,
    partial.map((p) => p.videoId),
  );

  const items: MusicSearchItem[] = partial.map((p) => ({
    ...p,
    duration: durations.get(p.videoId) ?? "",
  }));

  return NextResponse.json({ items });
}
