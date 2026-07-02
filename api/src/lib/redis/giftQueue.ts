import { getRedisClient, getRedisInstanceId, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";
import { redisPublish } from "./pubsub";

export type GiftQueueJob = {
  id: string;
  roomId?: string;
  streamId?: string;
  senderId?: string;
  payload: Record<string, unknown>;
  enqueuedAt: number;
};

const memoryStream: GiftQueueJob[] = [];

export async function giftQueueEnqueue(job: Omit<GiftQueueJob, "enqueuedAt">): Promise<void> {
  const full: GiftQueueJob = { ...job, enqueuedAt: Date.now() };
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.xAdd(RedisKeys.gift.stream, "*", {
        data: JSON.stringify(full),
      });
      await redisPublish(RedisKeys.pubsub.gift, { type: "queued", job: full });
      return;
    } catch {
      /* fallback */
    }
  }
  memoryStream.push(full);
  await redisPublish(RedisKeys.pubsub.gift, { type: "queued", job: full });
}

export type GiftJobHandler = (job: GiftQueueJob) => Promise<void>;

let workerRunning = false;

export async function startGiftQueueWorker(handler: GiftJobHandler): Promise<void> {
  if (workerRunning) return;
  workerRunning = true;
  const consumer = RedisKeys.gift.consumer(getRedisInstanceId());

  const ensureGroup = async () => {
    if (!isRedisReady() || !getRedisClient()) return;
    try {
      await getRedisClient()!.xGroupCreate(
        RedisKeys.gift.stream,
        RedisKeys.gift.group,
        "0",
        { MKSTREAM: true },
      );
    } catch (e) {
      const msg = e instanceof Error ? e.message : "";
      if (!msg.includes("BUSYGROUP")) throw e;
    }
  };

  const loop = async () => {
    while (workerRunning) {
      if (isRedisReady() && getRedisClient()) {
        try {
          await ensureGroup();
          const rows = await getRedisClient()!.xReadGroup(
            RedisKeys.gift.group,
            consumer,
            [{ key: RedisKeys.gift.stream, id: ">" }],
            { COUNT: 10, BLOCK: 2000 },
          );
          if (rows) {
            for (const stream of rows) {
              for (const entry of stream.messages) {
                const raw = entry.message.data;
                if (typeof raw !== "string") continue;
                try {
                  const job = JSON.parse(raw) as GiftQueueJob;
                  await handler(job);
                  await getRedisClient()!.xAck(
                    RedisKeys.gift.stream,
                    RedisKeys.gift.group,
                    entry.id,
                  );
                } catch (err) {
                  console.error("[gift-queue] işlem hatası", err);
                }
              }
            }
          }
          continue;
        } catch {
          /* bellek kuyruğuna düş */
        }
      }
      const job = memoryStream.shift();
      if (job) {
        try {
          await handler(job);
        } catch (err) {
          console.error("[gift-queue] bellek işlem hatası", err);
        }
      } else {
        await new Promise((r) => setTimeout(r, 500));
      }
    }
  };

  void loop();
}

export function stopGiftQueueWorker() {
  workerRunning = false;
}
