/**
 * YouTube Data API v3 — müzik arama (web + Flutter ortak).
 * api/src/lib/youtubeMusicSearch.ts ile senkron tutun.
 */

export type MusicSearchItem = {
  videoId: string;
  title: string;
  thumbnail: string;
  channelTitle: string;
  duration: string;
};

export class YoutubeApiNotConfiguredError extends Error {
  constructor() {
    super("YOUTUBE_API_KEY tanımlı değil");
    this.name = "YoutubeApiNotConfiguredError";
  }
}

function getApiKey(): string {
  const key = process.env.YOUTUBE_API_KEY?.trim();
  if (!key) throw new YoutubeApiNotConfiguredError();
  return key;
}

export function formatIso8601Duration(iso?: string | null): string {
  if (!iso || !iso.startsWith("PT")) return "";
  const m = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!m) return "";
  const h = Number(m[1] ?? 0);
  const min = Number(m[2] ?? 0);
  const sec = Number(m[3] ?? 0);
  const total = h * 3600 + min * 60 + sec;
  if (total <= 0) return "";
  const mm = Math.floor(total / 60);
  const ss = total % 60;
  return `${mm}:${ss.toString().padStart(2, "0")}`;
}

function extractYoutubeId(input: string): string | null {
  const t = input.trim();
  const m =
    t.match(/[?&]v=([a-zA-Z0-9_-]{6,})/) ??
    t.match(/youtu\.be\/([a-zA-Z0-9_-]{6,})/);
  return m?.[1] ?? null;
}

async function fetchVideoDurations(
  apiKey: string,
  videoIds: string[],
): Promise<Map<string, string>> {
  const map = new Map<string, string>();
  if (videoIds.length === 0) return map;
  const url = new URL("https://www.googleapis.com/youtube/v3/videos");
  url.searchParams.set("part", "contentDetails");
  url.searchParams.set("id", videoIds.join(","));
  url.searchParams.set("key", apiKey);
  const res = await fetch(url, { headers: { Accept: "application/json" } });
  if (!res.ok) return map;
  const data = (await res.json()) as {
    items?: Array<{ id?: string; contentDetails?: { duration?: string } }>;
  };
  for (const row of data.items ?? []) {
    const id = row.id?.trim() ?? "";
    if (!id) continue;
    const d = formatIso8601Duration(row.contentDetails?.duration);
    if (d) map.set(id, d);
  }
  return map;
}

export async function searchMusicViaYoutubeApi(
  query: string,
): Promise<MusicSearchItem[]> {
  const q = query.trim();
  if (q.length < 2) return [];

  const apiKey = getApiKey();

  if (/youtube\.com|youtu\.be/i.test(q)) {
    const id = extractYoutubeId(q);
    if (!id) return [];
    const durations = await fetchVideoDurations(apiKey, [id]);
    return [
      {
        videoId: id,
        title: "YouTube bağlantısı",
        thumbnail: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
        channelTitle: "",
        duration: durations.get(id) ?? "",
      },
    ];
  }

  const searchUrl = new URL("https://www.googleapis.com/youtube/v3/search");
  searchUrl.searchParams.set("part", "snippet");
  searchUrl.searchParams.set("type", "video");
  searchUrl.searchParams.set("maxResults", "12");
  searchUrl.searchParams.set("q", q);
  searchUrl.searchParams.set("key", apiKey);

  const searchRes = await fetch(searchUrl, {
    headers: { Accept: "application/json" },
  });
  if (!searchRes.ok) {
    const errBody = (await searchRes.json().catch(() => ({}))) as {
      error?: { message?: string };
    };
    throw new Error(
      errBody.error?.message ?? `YouTube API hatası (${searchRes.status})`,
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

  const hits: Array<{
    videoId: string;
    title: string;
    thumbnail: string;
    channelTitle: string;
  }> = [];

  for (const row of searchData.items ?? []) {
    const vid = row.id?.videoId?.trim() ?? "";
    if (vid.length < 6) continue;
    const sn = row.snippet;
    const thumb =
      sn?.thumbnails?.medium?.url ??
      sn?.thumbnails?.default?.url ??
      `https://i.ytimg.com/vi/${vid}/hqdefault.jpg`;
    hits.push({
      videoId: vid,
      title: sn?.title?.trim() || "Video",
      thumbnail: thumb,
      channelTitle: sn?.channelTitle?.trim() || "",
    });
  }

  if (hits.length === 0) return [];

  const durations = await fetchVideoDurations(
    apiKey,
    hits.map((h) => h.videoId),
  );

  return hits.map((h) => ({
    ...h,
    duration: durations.get(h.videoId) ?? "",
  }));
}
