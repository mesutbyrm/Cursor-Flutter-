import { getRedisClient, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";
import { RedisKeys } from "./keys";

export type NotificationJob = {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  enqueuedAt: number;
};

const memoryQueue: NotificationJob[] = [];

export async function notificationEnqueue(
  job: Omit<NotificationJob, "enqueuedAt">,
): Promise<void> {
  const full: NotificationJob = { ...job, enqueuedAt: Date.now() };
  if (isRedisReady() && getRedisClient()) {
    try {
      await getRedisClient()!.lPush(RedisKeys.notify.queue, JSON.stringify(full));
      return;
    } catch {
      /* fallback */
    }
  }
  memoryQueue.push(full);
}

export type NotificationHandler = (job: NotificationJob) => Promise<void>;

let workerOn = false;

export async function startNotificationWorker(handler: NotificationHandler): Promise<void> {
  if (workerOn) return;
  workerOn = true;

  const loop = async () => {
    while (workerOn) {
      let raw: string | null = null;
      if (isRedisReady() && getRedisClient()) {
        try {
          raw = await getRedisClient()!.rPop(RedisKeys.notify.queue);
        } catch {
          raw = memoryQueue.length ? JSON.stringify(memoryQueue.shift()) : null;
        }
      } else {
        const job = memoryQueue.shift();
        raw = job ? JSON.stringify(job) : null;
      }
      if (!raw) {
        await new Promise((r) => setTimeout(r, 400));
        continue;
      }
      try {
        const job = JSON.parse(raw) as NotificationJob;
        await handler(job);
      } catch (err) {
        console.error("[notify-queue]", err);
      }
    }
  };
  void loop();
}

export function stopNotificationWorker() {
  workerOn = false;
}
