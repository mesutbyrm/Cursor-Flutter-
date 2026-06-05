import { Router } from "express";
import { requireAuth } from "../middleware/requireAuth";
import { jsonError } from "../lib/jsonError";
import {
  searchMusicViaYoutubeApi,
  YoutubeApiNotConfiguredError,
} from "../lib/youtubeMusicSearch";

export const musicRouter = Router();

/**
 * GET /api/music/search?q=...
 * JWT zorunlu. Web + Flutter ortak müzik arama ucu.
 */
musicRouter.get("/search", requireAuth, async (req, res) => {
  const q = String(req.query.q ?? req.query.query ?? "").trim();
  if (q.length < 2) {
    return jsonError(res, 400, "Arama en az 2 karakter olmalı");
  }
  try {
    const items = await searchMusicViaYoutubeApi(q);
    return res.status(200).json({ items });
  } catch (e) {
    if (e instanceof YoutubeApiNotConfiguredError) {
      return jsonError(
        res,
        503,
        "YOUTUBE_API_KEY sunucuda tanımlı değil. Yönetici panelinden ekleyin.",
      );
    }
    const msg = e instanceof Error ? e.message : "YouTube araması başarısız";
    return jsonError(res, 502, msg);
  }
});
