import { getRedisSubscriber, isRedisReady } from "./client";
import { memoryKv } from "./memoryKv";

type Handler = (payload: unknown) => void | Promise<void>;

const localHandlers = new Map<string, Set<Handler>>();
const memoryChannels = new Map<string, unknown[]>();

export async function redisPublish(channel: string, payload: unknown): Promise<void> {
  if (isRedisReady() && getRedisSubscriber()) {
    try {
      const client = (await import("./client")).getRedisClient();
      if (client) {
        await client.publish(channel, JSON.stringify(payload));
        return;
      }
    } catch {
      /* local */
    }
  }
  const handlers = localHandlers.get(channel);
  if (handlers) {
    for (const fn of handlers) {
      void fn(payload);
    }
  }
  const q = memoryChannels.get(channel) ?? [];
  q.push(payload);
  memoryChannels.set(channel, q.slice(-200));
}

export async function redisSubscribe(
  channel: string,
  handler: Handler,
): Promise<() => void> {
  let set = localHandlers.get(channel);
  if (!set) {
    set = new Set();
    localHandlers.set(channel, set);
  }
  set.add(handler);

  if (isRedisReady()) {
    const sub = getRedisSubscriber();
    if (sub) {
      await sub.subscribe(channel, (message) => {
        try {
          void handler(JSON.parse(message));
        } catch {
          void handler(message);
        }
      });
    }
  }

  return () => {
    set?.delete(handler);
  };
}
