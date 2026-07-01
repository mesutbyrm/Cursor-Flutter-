import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

function watchUrl(videoIdOrUrl: string): string {
  const t = videoIdOrUrl.trim();
  if (/youtube\.com|youtu\.be/i.test(t)) return t;
  return `https://www.youtube.com/watch?v=${t}`;
}

/**
 * yt-dlp ile güncel ses akış URL'si (googlevideo).
 * Üretimde `yt-dlp` PATH'te olmalı; yoksa null döner (Piped yedek).
 *
 * Not: canlifal.com Node-only ortamda yt-dlp yoktur; mobil müzik YouTube
 * IFrame embed ile çalar (bu çözümleyici kullanılmaz).
 */
export async function resolveStreamViaYtdlp(
  videoIdOrUrl: string,
): Promise<string | null> {
  const input = watchUrl(videoIdOrUrl);
  try {
    const { stdout } = await execFileAsync(
      "yt-dlp",
      [
        "-f",
        "bestaudio[ext=m4a]/bestaudio/best",
        "--get-url",
        "--no-playlist",
        "--no-warnings",
        input,
      ],
      { timeout: 28_000, maxBuffer: 2 * 1024 * 1024 },
    );
    const line = stdout
      .trim()
      .split("\n")
      .map((s) => s.trim())
      .find((s) => s.startsWith("http"));
    return line ?? null;
  } catch {
    return null;
  }
}
