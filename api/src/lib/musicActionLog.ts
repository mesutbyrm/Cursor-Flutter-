import { prisma } from "./prisma";

export type MusicLogAction =
  | "request"
  | "debit"
  | "play"
  | "pause"
  | "resume"
  | "stop"
  | "close"
  | "skip"
  | "unauthorized";

export async function logMusicAction(input: {
  roomId: string;
  userId?: string | null;
  username?: string | null;
  action: MusicLogAction;
  metadata?: Record<string, unknown>;
}) {
  try {
    await prisma.musicActionLog.create({
      data: {
        roomId: input.roomId,
        userId: input.userId ?? null,
        username: input.username ?? null,
        action: input.action,
        metadata: input.metadata ? JSON.stringify(input.metadata) : null,
      },
    });
  } catch {
    // Yerel geliştirme / DB yok — sessizce atla
  }
}
