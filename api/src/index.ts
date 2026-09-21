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
import storiesRouter from "./routes/stories";
import socialFeaturesRouter from "./routes/social_features";
import directMessagesRouter from "./routes/direct_messages";
import shareSettingsRouter from "./routes/share_settings";
import userRecommendationsRouter from "./routes/user_recommendations";
import userPreferencesRouter from "./routes/user_preferences";
import performanceMonitoringRouter from "./routes/performance_monitoring";
import twoFactorAuthRouter from "./routes/two_factor_auth";
import accessibilityRouter from "./routes/accessibility";
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
import { liveFalRequestsRouter } from "./routes/live_fal_requests";
import { liveFieldRouter } from "./routes/live_field";
import { shortVideosRouter } from "./routes/short_videos";
import { gamesRouter } from "./routes/games";
import { voiceRoomSettingsRouter } from "./routes/voice_room_settings";
import { siteAnimationsRouter } from "./routes/site_animations";
import { referralRouter } from "./routes/referral";
import { streamCampaignsRouter } from "./routes/stream_campaigns";
import { pkBattleAdvancedRouter } from "./routes/pk_battle_advanced";
import { giftSystemAdvancedRouter } from "./routes/gift_system_advanced";
import { streamMembershipOffersRouter } from "./routes/stream_membership_offers";
import { coBroadcastAdvancedRouter } from "./routes/co_broadcast_advanced";
import { streamAdsSponsorsRouter } from "./routes/stream_ads_sponsors";
import { hostTiersBadgesRouter } from "./routes/host_tiers_badges";
import { fortuneRoomRouter } from "./routes/fortune_room";
import { subscriptionsRouter } from "./routes/subscriptions";
import { achievementsRouter } from "./routes/achievements";
import { notificationPreferencesRouter } from "./routes/notification_preferences";
import aiCopilotRouter from "./routes/ai_copilot";
import fortuneMatchingRouter from "./routes/fortune_matching";
import analyticsRouter from "./routes/analytics";
import voiceFortuneRouter from "./routes/voice_fortune";
import agoraRouter from "./routes/agora";
import voiceSessionsRouter from "./routes/voice_sessions";
import voiceRoomRolesRouter from "./routes/voice_room_roles";
import voiceModerationRouter from "./routes/voice_moderation";
import voiceStatsRouter from "./routes/voice_stats";
import voiceRecommendationsRouter from "./routes/voice_recommendations";
import { roomInfoRouter } from "./routes/room_info";
import { roomPrivacyRouter } from "./routes/room_privacy";
import { roomActivityLogRouter } from "./routes/room_activity_log";
import { roomHistoryRouter } from "./routes/room_history";
import { roomAchievementsRouter } from "./routes/room_achievements";
import { roomRecordingRouter } from "./routes/room_recording";
import { advancedAnalyticsRouter } from "./routes/advanced_analytics";
import { liveStreamAnalyticsRouter } from "./routes/live_stream_analytics";
import { streamModerationRouter } from "./routes/stream_moderation";
import { streamChatFilterRouter } from "./routes/stream_chat_filter";
import { streamQualityRouter } from "./routes/stream_quality";
import { streamVipRouter } from "./routes/stream_vip";
import { streamTrendingRouter } from "./routes/stream_trending";
import { streamAchievementsRouter } from "./routes/stream_achievements";
import { streamRecordingRouter } from "./routes/stream_recording";
import { hostStreamStatsRouter } from "./routes/host_stream_stats";
import { initGiftSocket } from "./socket/giftHub";
import { runAdminPaymentBootstrap } from "./lib/adminPaymentBootstrap";
import { bootstrapSiteAnimations } from "./lib/siteAnimationBootstrap";
import { bootstrapRedisStack, isRedisReady } from "./lib/redis/bootstrap";
import { rateLimitMiddleware } from "./lib/redis/rateLimit";
import path from "node:path";

const app = express();
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") ?? true, credentials: true }));
app.use(express.json({ limit: "512kb" }));
app.use("/uploads/shorts", express.static(path.join(process.cwd(), "uploads", "shorts")));

const v1 = express.Router();
v1.get("/health", (_req, res) => {
  res.status(200).json({
    success: true,
    data: {
      status: "ok",
      redis: isRedisReady() ? "connected" : "fallback",
    },
  });
});
v1.use("/auth", authRouter);
v1.use("/users", usersRouter);
v1.use("/", socialRouter);

app.use("/api/v1", v1);
app.use("/api/auth", rateLimitMiddleware("login"));
app.use("/api/auth", authRouter);
app.use("/api/auth", authMobileRouter);
app.use("/api/social", socialPostsRouter);
app.use("/api/gifts", giftsRouter);
app.use("/api/video-streams", videoStreamsRouter);
app.use("/api/video-streams", videoStreamGiftsRouter);
app.use("/api", walletRouter);
app.use("/api", rateLimitMiddleware("api"));
app.use("/api", voiceRoomSettingsRouter);
app.use("/api", siteAnimationsRouter);
app.use("/api", referralRouter);
app.use("/api/room", fortuneRoomRouter);
app.use("/api", socialRouter);
app.use("/api", homeRouter);
app.use("/api", usersRouter);
app.use("/api/users", profileExtrasRouter);
app.use("/api/user", userFlutterApiRouter);
app.use("/api/notifications", notificationsRouter);
app.use("/api/notifications", notificationPreferencesRouter);
app.use("/api/subscriptions", subscriptionsRouter);
app.use("/api/achievements", achievementsRouter);
app.use("/api/ai-copilot", aiCopilotRouter);
app.use("/api/fortune-matching", fortuneMatchingRouter);
app.use("/api/analytics", analyticsRouter);
app.use("/api/voice-fortune", voiceFortuneRouter);
app.use("/api/social-features", socialFeaturesRouter);
app.use("/api/direct-messages", directMessagesRouter);
app.use("/api/stories", storiesRouter);
app.use("/api/share-settings", shareSettingsRouter);
app.use("/api/recommendations", userRecommendationsRouter);
app.use("/api/preferences", userPreferencesRouter);
app.use("/api/performance", performanceMonitoringRouter);
app.use("/api/2fa", twoFactorAuthRouter);
app.use("/api/accessibility", accessibilityRouter);
app.use("/api/devices", devicesRouter);
app.use("/api/messages", rateLimitMiddleware("message"), messagesRouter);
app.use("/api/chat", chatRoomsRouter);
app.use("/api/music", musicRouter);
app.use("/api", liveFieldRouter);
app.use("/api/trtc", trtcRouter);
app.use("/api/agora", agoraRouter);
app.use("/api/voice", voiceSessionsRouter);
app.use("/api/voice", voiceStatsRouter);
app.use("/api/chat", voiceRoomRolesRouter);
app.use("/api/chat", voiceModerationRouter);
app.use("/api/chat", voiceRecommendationsRouter);
app.use("/api", roomInfoRouter);
app.use("/api", roomPrivacyRouter);
app.use("/api", roomActivityLogRouter);
app.use("/api", roomHistoryRouter);
app.use("/api", roomAchievementsRouter);
app.use("/api", roomRecordingRouter);
app.use("/api", advancedAnalyticsRouter);
app.use("/api", liveStreamAnalyticsRouter);
app.use("/api", streamModerationRouter);
app.use("/api", streamChatFilterRouter);
app.use("/api", streamQualityRouter);
app.use("/api", streamVipRouter);
app.use("/api", streamTrendingRouter);
app.use("/api", streamAchievementsRouter);
app.use("/api", streamRecordingRouter);
app.use("/api", hostStreamStatsRouter);
app.use("/api", streamCampaignsRouter);
app.use("/api", pkBattleAdvancedRouter);
app.use("/api", giftSystemAdvancedRouter);
app.use("/api", streamMembershipOffersRouter);
app.use("/api", coBroadcastAdvancedRouter);
app.use("/api", streamAdsSponsorsRouter);
app.use("/api", hostTiersBadgesRouter);
app.use("/api/reports", reportsRouter);
app.use("/api/pk", pkBattlesRouter);
app.use("/api", liveFalRequestsRouter);
app.use("/api/short-videos", shortVideosRouter);
app.use("/api", gamesRouter);

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
  void bootstrapRedisStack();
  void runAdminPaymentBootstrap();
  void bootstrapSiteAnimations();
});

process.on("SIGTERM", () => {
  void import("./lib/redis/bootstrap").then((m) => m.teardownRedisStack());
});
