import { prisma } from "./prisma";

export async function createNotification(input: {
  userId?: string;
  title: string;
  body?: string;
  type?: string;
  targetPath?: string;
  targetId?: string;
}) {
  return prisma.appNotification.create({
    data: {
      userId: input.userId ?? null,
      title: input.title,
      body: input.body,
      type: input.type ?? "system",
      targetPath: input.targetPath,
      targetId: input.targetId,
    },
  });
}
