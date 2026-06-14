/** MP4 mvhd atomundan süre (saniye) — ffmpeg gerektirmez. */
export function getMp4DurationSeconds(buffer: Buffer): number | null {
  if (buffer.length < 32) return null;
  const max = Math.min(buffer.length, 12 * 1024 * 1024);
  for (let i = 0; i < max - 8; i++) {
    const size = buffer.readUInt32BE(i);
    if (size < 8 || size > max - i) continue;
    const type = buffer.toString("ascii", i + 4, i + 8);
    if (type !== "mvhd") continue;
    const version = buffer[i + 8];
    if (version === 0) {
      if (i + 8 + 20 > buffer.length) return null;
      const timescale = buffer.readUInt32BE(i + 20);
      const duration = buffer.readUInt32BE(i + 24);
      if (timescale <= 0) return null;
      return duration / timescale;
    }
    if (version === 1) {
      if (i + 8 + 32 > buffer.length) return null;
      const timescale = buffer.readUInt32BE(i + 28);
      const durationHi = buffer.readUInt32BE(i + 32);
      const durationLo = buffer.readUInt32BE(i + 36);
      const duration = durationHi * 2 ** 32 + durationLo;
      if (timescale <= 0) return null;
      return duration / timescale;
    }
  }
  return null;
}

export const MAX_SHORT_VIDEO_SECONDS = 15;

export function assertShortVideoDuration(seconds: number | null): void {
  if (seconds == null || !Number.isFinite(seconds)) {
    throw new Error("DURATION_UNKNOWN");
  }
  if (seconds > MAX_SHORT_VIDEO_SECONDS + 0.25) {
    throw new Error("DURATION_TOO_LONG");
  }
  if (seconds <= 0.1) {
    throw new Error("DURATION_TOO_SHORT");
  }
}
