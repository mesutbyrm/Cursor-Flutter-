import { getRedisClient, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";

export type ShortsScoreInput = {
  videoId: string;
  likes?: number;
  views?: number;
  shares?: number;
  watchTimeMs?: number;
};

/** Trend skoru: likes*3 + views*0.1 + shares*5 + watchTime(dk)*2 */
export function computeTrendScore(input: ShortsScoreInput): number {
  const likes = input.likes ?? 0;
  const views = input.views ?? 0;
  const shares = input.shares ?? 0;
  const watchMin = (input.watchTimeMs ?? 0) / 60_000;
  return likes * 3 + views * 0.1 + shares * 5 + watchMin * 2;
}

export async function shortsRecordEngagement(input: ShortsScoreInput): Promise<number> {
  const score = computeTrendScore(input);
  const key = RedisKeys.shorts.trending;
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.zIncrBy(key, score, input.videoId);
      return score;
    } catch {
      /* fallback */
    }
  }
  memoryKv.zincrby(key, score, input.videoId);
  return score;
}

export async function shortsTrendingIds(limit = 50): Promise<string[]> {
  const key = RedisKeys.shorts.trending;
  if (isRedisReady() && getRedisClient()) {
    try {
      return await getRedisClient()!.zRange(key, 0, limit - 1, { REV: true });
    } catch {
      return memoryKv.zrevrange(key, 0, limit - 1);
    }
  }
  return memoryKv.zrevrange(key, 0, limit - 1);
}

export async function shortsSeedFromDb(
  rows: Array<{
    id: string;
    likesCount?: number;
    viewCount?: number;
    shareCount?: number;
    watchTimeMs?: number;
  }>,
): Promise<void> {
  for (const row of rows) {
    await shortsRecordEngagement({
      videoId: row.id,
      likes: row.likesCount,
      views: row.viewCount,
      shares: row.shareCount,
      watchTimeMs: row.watchTimeMs,
    });
  }
}
