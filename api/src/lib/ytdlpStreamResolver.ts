import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

function watchUrl(videoIdOrUrl: string): string {
  const t = videoIdOrUrl.trim();
  if (/youtube\.com|youtu\.be/i.test(t)) return t;
  return `https://www.youtube.com/watch?v=${t}`;
}

const YTDLP_ARGS = [
  "-f",
  "bestaudio[ext=m4a]/bestaudio/best",
  "--get-url",
  "--no-playlist",
  "--no-warnings",
];

async function runResolver(
  cmd: string,
  args: string[],
): Promise<string | null> {
  try {
    const { stdout } = await execFileAsync(cmd, args, {
      timeout: 28_000,
      maxBuffer: 2 * 1024 * 1024,
    });
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

/**
 * yt-dlp ile güncel ses akış URL'si (googlevideo).
 *
 * Önce `yt-dlp` binary'si (PATH), olmazsa `python3 -m yt_dlp` denenir —
 * pip modülü kurar ama bazen binary'yi PATH'e koymaz. İkisi de yoksa null
 * döner ve çağıran Piped yedeğine geçer.
 */
export async function resolveStreamViaYtdlp(
  videoIdOrUrl: string,
): Promise<string | null> {
  const input = watchUrl(videoIdOrUrl);
  const viaBinary = await runResolver("yt-dlp", [...YTDLP_ARGS, input]);
  if (viaBinary) return viaBinary;
  // Fallback: pip ile kurulu modül (binary PATH'te değilse).
  return runResolver("python3", ["-m", "yt_dlp", ...YTDLP_ARGS, input]);
}
