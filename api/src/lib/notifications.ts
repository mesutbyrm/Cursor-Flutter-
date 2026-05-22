import { prisma } from "./prisma";
import { sendOneSignalToUser } from "./onesignal";

export async function createNotification(input: {
  userId?: string;
  title: string;
  body?: string;
  type?: string;
  data?: string | Record<string, unknown>;
  targetPath?: string;
  targetId?: string;
}) {
  const dataStr =
    input.data == null
      ? undefined
      : typeof input.data === "string"
        ? input.data
        : JSON.stringify(input.data);
  const row = await prisma.appNotification.create({
    data: {
      userId: input.userId ?? null,
      title: input.title,
      body: input.body,
      type: input.type ?? "system",
      data: dataStr,
      targetPath: input.targetPath,
      targetId: input.targetId,
    },
  });

  if (input.userId) {
    const extra: Record<string, string> = {};
    if (input.targetPath) extra.targetPath = input.targetPath;
    if (input.targetId) extra.targetId = input.targetId;
    if (input.type) extra.type = input.type;
    void sendOneSignalToUser({
      userId: input.userId,
      title: input.title,
      body: input.body,
      data: Object.keys(extra).length ? extra : undefined,
    });
  }

  return row;
}
