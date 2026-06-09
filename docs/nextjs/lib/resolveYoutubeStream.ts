/**
 * YouTube watch URL → doğrudan ses akışı (Piped API).
 * api/src/lib/chatRoomStore.ts resolveYoutubeStreamUrl ile uyumlu.
 */

const PIPED_API_HOSTS = [
  "https://pipedapi.kavin.rocks",
  "https://pipedapi.adminforge.de",
  "https://pipedapi.syncpundit.io",
  "https://pipedapi.leptons.xyz",
];

export function extractYoutubeId(input: string): string | null {
  const t = input.trim();
  const m =
    t.match(/[?&]v=([a-zA-Z0-9_-]{6,})/) ??
    t.match(/youtu\.be\/([a-zA-Z0-9_-]{6,})/);
  return m?.[1] ?? null;
}

async function resolveViaPipedHost(
  host: string,
  videoId: string,
): Promise<string | null> {
  try {
    const res = await fetch(`${host}/streams/${videoId}`, {
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      audioStreams?: Array<{ url?: string; bitrate?: number }>;
      audioOnly?: Array<{ url?: string; bitrate?: number }>;
    };
    const streams = [...(data.audioStreams ?? []), ...(data.audioOnly ?? [])];
    if (streams.length === 0) return null;
    streams.sort((a, b) => (b.bitrate ?? 0) - (a.bitrate ?? 0));
    const url = streams[0]?.url;
    return url && url.startsWith("http") ? url : null;
  } catch {
    return null;
  }
}

export async function resolveYoutubeStreamUrl(
  youtubeUrlOrId: string,
): Promise<string | null> {
  const id =
    extractYoutubeId(youtubeUrlOrId) ??
    (youtubeUrlOrId.length <= 15 && !youtubeUrlOrId.includes("/")
      ? youtubeUrlOrId
      : null);
  if (!id) return null;
  for (const host of PIPED_API_HOSTS) {
    const stream = await resolveViaPipedHost(host, id);
    if (stream) return stream;
  }
  return null;
}
