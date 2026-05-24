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

    socket.on("joinRoom", (payload: { roomId?: string }) => {
      const id = payload?.roomId?.trim();
      if (id) socket.join(voiceRoom(id));
    });

    socket.on("leaveRoom", (payload: { roomId?: string }) => {
      const id = payload?.roomId?.trim();
      if (id) socket.leave(voiceRoom(id));
    });
  });

  return io;
}

function streamRoom(streamId: string) {
  return `stream:${streamId}`;
}

function voiceRoom(roomId: string) {
  return `room:${roomId}`;
}

export function emitGiftEvent(streamId: string, payload: Record<string, unknown>) {
  if (!io) return;
  io.to(streamRoom(streamId)).emit("gift", payload);
  io.to(streamRoom(streamId)).emit("giftSent", payload);
}

export function emitGiftRoomEvent(roomId: string, payload: Record<string, unknown>) {
  if (!io) return;
  io.to(voiceRoom(roomId)).emit("gift", payload);
  io.to(voiceRoom(roomId)).emit("giftSent", payload);
}

export function emitChatRoomMessage(
  roomId: string,
  payload: Record<string, unknown>,
) {
  if (!io) return;
  io.to(voiceRoom(roomId)).emit("chatMessage", payload);
  io.to(voiceRoom(roomId)).emit("message", payload);
  io.to(voiceRoom(roomId)).emit("roomMessage", payload);
}
