import type { Server as HttpServer } from "node:http";
import { Server } from "socket.io";

let io: Server | null = null;

export function initGiftSocket(httpServer: HttpServer) {
  io = new Server(httpServer, {
    cors: { origin: true, credentials: true },
    path: "/socket.io",
  });

  io.on("connection", (socket) => {
    socket.on("joinStream", (payload: { streamId?: string }) => {
      const id = payload?.streamId?.trim();
      if (id) socket.join(streamRoom(id));
    });

    socket.on("leaveStream", (payload: { streamId?: string }) => {
      const id = payload?.streamId?.trim();
      if (id) socket.leave(streamRoom(id));
    });
  });

  return io;
}

function streamRoom(streamId: string) {
  return `stream:${streamId}`;
}

export function emitGiftEvent(streamId: string, payload: Record<string, unknown>) {
  if (!io) return;
  io.to(streamRoom(streamId)).emit("gift", payload);
  io.to(streamRoom(streamId)).emit("giftSent", payload);
}
