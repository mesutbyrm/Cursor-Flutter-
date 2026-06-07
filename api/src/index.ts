import "dotenv/config";
import "express-async-errors";
import http from "node:http";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { authRouter } from "./routes/auth";
import { authMobileRouter } from "./routes/auth_mobile";
import { usersRouter } from "./routes/users";
import { profileExtrasRouter } from "./routes/profileExtras";
import { userFlutterApiRouter } from "./routes/userFlutterApi";
import { socialRouter } from "./routes/social";
import { homeRouter } from "./routes/home";
import { socialPostsRouter } from "./routes/socialPosts";
import { giftsRouter, videoStreamGiftsRouter } from "./routes/gifts";
import { videoStreamsRouter } from "./routes/video_streams";
import { walletRouter } from "./routes/wallet";
import { notificationsRouter } from "./routes/notifications";
import { devicesRouter } from "./routes/devices";
import { messagesRouter } from "./routes/messages";
import { chatRoomsRouter } from "./routes/chat_rooms";
import { musicRouter } from "./routes/music";
import { trtcRouter } from "./routes/trtc";
import { storiesRouter } from "./routes/stories";
import { reportsRouter } from "./routes/reports";
import {
  searchMusicViaYoutubeApi,
  toLegacyYoutubeHits,
  YoutubeApiNotConfiguredError,
} from "./lib/youtubeMusicSearch";
import { livekitRouter } from "./routes/livekit";
import { requireAuth } from "./middleware/requireAuth";
import { jsonError } from "./lib/jsonError";
import { fail } from "./lib/response";
import { pkBattlesRouter } from "./routes/pk_battles";
import { initGiftSocket } from "./socket/giftHub";

const app = express();
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") ?? true, credentials: true }));
app.use(express.json({ limit: "512kb" }));

const v1 = express.Router();
v1.get("/health", (_req, res) => {
  res.status(200).json({ success: true, data: { status: "ok" } });
});
v1.use("/auth", authRouter);
v1.use("/users", usersRouter);
v1.use("/", socialRouter);

app.use("/api/v1", v1);
app.use("/api/auth", authRouter);
app.use("/api/auth", authMobileRouter);
app.use("/api/social", socialPostsRouter);
app.use("/api/gifts", giftsRouter);
app.use("/api/video-streams", videoStreamsRouter);
app.use("/api/video-streams", videoStreamGiftsRouter);
app.use("/api", walletRouter);
app.use("/api", socialRouter);
app.use("/api", homeRouter);
app.use("/api", usersRouter);
app.use("/api/users", profileExtrasRouter);
app.use("/api/user", userFlutterApiRouter);
app.use("/api/notifications", notificationsRouter);
app.use("/api/devices", devicesRouter);
app.use("/api/messages", messagesRouter);
app.use("/api/chat", chatRoomsRouter);
app.use("/api/music", musicRouter);
app.use("/api/trtc", trtcRouter);
app.use("/api/stories", storiesRouter);
app.use("/api/social/stories", storiesRouter);
app.use("/api/reports", reportsRouter);
app.use("/api/pk", pkBattlesRouter);

/** @deprecated — GET /api/music/search kullanın */
app.get("/api/youtube/search", requireAuth, async (req, res) => {
  const q = String(req.query.q ?? req.query.query ?? "");
  try {
    const items = toLegacyYoutubeHits(await searchMusicViaYoutubeApi(q));
    return res.status(200).json({ items });
  } catch (e) {
    if (e instanceof YoutubeApiNotConfiguredError) {
      return jsonError(res, 503, e.message);
    }
    const msg = e instanceof Error ? e.message : "YouTube araması başarısız";
    return jsonError(res, 502, msg);
  }
});

app.use("/api/livekit", livekitRouter);

app.use((_req, res) => {
  return fail(res, 404, "NOT_FOUND", "Endpoint bulunamadı");
});

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  return fail(res, 500, "INTERNAL_ERROR", "Beklenmeyen sunucu hatası");
});

const port = Number(process.env.PORT) || 3000;
const server = http.createServer(app);
initGiftSocket(server);

server.listen(port, () => {
  console.log(`Canlifal API http://localhost:${port}/api/v1`);
  console.log(`Gift Socket.IO path /socket.io`);
});
