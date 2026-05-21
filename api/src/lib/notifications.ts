import { prisma } from "./prisma";

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
  return prisma.appNotification.create({
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
}
