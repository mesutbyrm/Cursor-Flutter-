import { initRedis, isRedisReady, shutdownRedis } from "./client";
import { startGiftQueueWorker } from "./giftQueue";
import { startNotificationWorker } from "./notificationQueue";
import { prisma } from "../prisma";
import { createNotification } from "../notifications";

let healthTimer: ReturnType<typeof setInterval> | null = null;

async function processGiftJob(job: import("./giftQueue").GiftQueueJob) {
  const payload = job.payload;
  const giftEventId = String(payload.giftEventId ?? "");
  if (!giftEventId) return;
  const exists = await prisma.giftEvent.findUnique({ where: { id: giftEventId } });
  if (exists) return;
  // Hediye zaten route'ta yazıldıysa atla; kuyruk yalnızca yoğunlukta sıralama içindir
}

async function processNotificationJob(
  job: import("./notificationQueue").NotificationJob,
) {
  await createNotification({
    userId: job.userId,
    title: job.title,
    body: job.body,
    data: job.data,
  });
}

export async function bootstrapRedisStack(): Promise<void> {
  await initRedis();
  if (isRedisReady()) {
    console.log("[redis] stack hazır");
  } else {
    console.log("[redis] fallback modu (bellek + PostgreSQL)");
  }

  await startGiftQueueWorker(processGiftJob);
  await startNotificationWorker(processNotificationJob);

  healthTimer = setInterval(() => {
    void initRedis();
  }, 30_000);
}

export async function teardownRedisStack(): Promise<void> {
  if (healthTimer) clearInterval(healthTimer);
  const { stopGiftQueueWorker } = await import("./giftQueue");
  const { stopNotificationWorker } = await import("./notificationQueue");
  stopGiftQueueWorker();
  stopNotificationWorker();
  await shutdownRedis();
}

export { isRedisReady };
