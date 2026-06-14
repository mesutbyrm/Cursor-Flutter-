import { Router } from "express";
import multer from "multer";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import {
  assertShortVideoDuration,
  getMp4DurationSeconds,
  MAX_SHORT_VIDEO_SECONDS,
} from "../lib/mp4Duration";
import { fail, ok } from "../lib/response";
import { uploadShortMedia } from "../lib/r2Storage";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 2 },
});

function authorPayload(user: {
  id: string;
  email: string;
  displayName: string | null;
  username: string | null;
  avatarUrl: string | null;
}) {
  return {
    id: user.id,
    userId: user.id,
    username: user.username ?? user.email.split("@")[0],
    displayName: user.displayName ?? user.username ?? user.email.split("@")[0],
    avatarUrl: user.avatarUrl,
  };
}

function videoPayload(
  v: {
    id: string;
    userId: string;
    videoUrl: string;
    thumbnailUrl: string | null;
    description: string | null;
    viewsCount: number;
    likesCount: number;
    commentsCount: number;
    durationSec: number | null;
    createdAt: Date;
    user: {
      id: string;
      email: string;
      displayName: string | null;
      username: string | null;
      avatarUrl: string | null;
    };
  },
  extras?: { likedByMe?: boolean; viewedByMe?: boolean },
) {
  return {
    id: v.id,
    userId: v.userId,
    videoUrl: v.videoUrl,
    thumbnailUrl: v.thumbnailUrl,
    description: v.description,
    viewsCount: v.viewsCount,
    likesCount: v.likesCount,
    commentsCount: v.commentsCount,
    durationSec: v.durationSec,
    createdAt: v.createdAt.toISOString(),
    author: authorPayload(v.user),
    likedByMe: extras?.likedByMe ?? false,
    viewedByMe: extras?.viewedByMe ?? false,
  };
}

export const shortVideosRouter = Router();

/** GET /api/short-videos — dikey feed (cursor pagination) */
shortVideosRouter.get("/", optionalAuth, async (req, res) => {
  const limit = Math.min(20, Math.max(1, Number(req.query.limit ?? 10)));
  const cursor =
    typeof req.query.cursor === "string" && req.query.cursor.trim()
      ? req.query.cursor.trim()
      : undefined;
  const userId = req.userId;

  const rows = await prisma.shortVideo.findMany({
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    orderBy: { createdAt: "desc" },
    include: { user: true },
  });

  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;
  const ids = page.map((r) => r.id);

  let likedSet = new Set<string>();
  let viewedSet = new Set<string>();
  if (userId && ids.length > 0) {
    const [likes, views] = await Promise.all([
      prisma.shortVideoLike.findMany({
        where: { userId, videoId: { in: ids } },
        select: { videoId: true },
      }),
      prisma.shortVideoView.findMany({
        where: { userId, videoId: { in: ids } },
        select: { videoId: true },
      }),
    ]);
    likedSet = new Set(likes.map((l) => l.videoId));
    viewedSet = new Set(views.map((v) => v.videoId));
  }

  const videos = page.map((v) =>
    videoPayload(v, {
      likedByMe: likedSet.has(v.id),
      viewedByMe: viewedSet.has(v.id),
    }),
  );

  return ok(res, {
    videos,
    nextCursor: hasMore ? page[page.length - 1]?.id : null,
    hasMore,
    maxDurationSec: MAX_SHORT_VIDEO_SECONDS,
  });
});

/** POST /api/short-videos/upload — video + thumbnail (multipart) */
shortVideosRouter.post(
  "/upload",
  requireAuth,
  upload.fields([
    { name: "video", maxCount: 1 },
    { name: "thumbnail", maxCount: 1 },
  ]),
  async (req, res) => {
    const files = req.files as {
      video?: Express.Multer.File[];
      thumbnail?: Express.Multer.File[];
    };
    const videoFile = files.video?.[0];
    if (!videoFile?.buffer?.length) {
      return fail(res, 400, "MISSING_VIDEO", "Video dosyası gerekli");
    }
    if (!videoFile.mimetype?.includes("mp4") && !videoFile.originalname?.endsWith(".mp4")) {
      return fail(res, 400, "INVALID_FORMAT", "Yalnızca MP4 (H.264) desteklenir");
    }

    let durationSec: number | null;
    try {
      durationSec = getMp4DurationSeconds(videoFile.buffer);
      assertShortVideoDuration(durationSec);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "DURATION_INVALID";
      if (msg === "DURATION_TOO_LONG") {
        return fail(
          res,
          400,
          "DURATION_TOO_LONG",
          `Video en fazla ${MAX_SHORT_VIDEO_SECONDS} saniye olabilir`,
        );
      }
      return fail(res, 400, "DURATION_INVALID", "Video süresi okunamadı");
    }

    const description =
      typeof req.body.description === "string"
        ? req.body.description.trim().slice(0, 500)
        : "";

    let videoUrl: string;
    let thumbnailUrl: string | null = null;
    try {
      const uploaded = await uploadShortMedia({
        buffer: videoFile.buffer,
        contentType: "video/mp4",
        ext: "mp4",
        folder: "videos",
      });
      videoUrl = uploaded.url;

      const thumbFile = files.thumbnail?.[0];
      if (thumbFile?.buffer?.length) {
        const thumb = await uploadShortMedia({
          buffer: thumbFile.buffer,
          contentType: thumbFile.mimetype || "image/jpeg",
          ext: thumbFile.mimetype?.includes("png") ? "png" : "jpg",
          folder: "thumbnails",
        });
        thumbnailUrl = thumb.url;
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "UPLOAD_FAILED";
      if (msg === "FILE_TOO_LARGE") {
        return fail(res, 400, "FILE_TOO_LARGE", "Video en fazla 10 MB olabilir");
      }
      return fail(res, 502, "UPLOAD_FAILED", "Video yüklenemedi");
    }

    const row = await prisma.shortVideo.create({
      data: {
        userId: req.userId!,
        videoUrl,
        thumbnailUrl,
        description: description || null,
        durationSec,
      },
      include: { user: true },
    });

    return ok(res, { video: videoPayload(row) }, 201);
  },
);

/** POST /api/short-videos/:id/like — beğeni toggle */
shortVideosRouter.post("/:id/like", requireAuth, async (req, res) => {
  const videoId = req.params.id;
  const userId = req.userId!;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");

  const existing = await prisma.shortVideoLike.findUnique({
    where: { videoId_userId: { videoId, userId } },
  });

  if (existing) {
    await prisma.$transaction([
      prisma.shortVideoLike.delete({ where: { id: existing.id } }),
      prisma.shortVideo.update({
        where: { id: videoId },
        data: { likesCount: { decrement: 1 } },
      }),
    ]);
    return ok(res, { liked: false, likesCount: Math.max(0, video.likesCount - 1) });
  }

  await prisma.$transaction([
    prisma.shortVideoLike.create({ data: { videoId, userId } }),
    prisma.shortVideo.update({
      where: { id: videoId },
      data: { likesCount: { increment: 1 } },
    }),
  ]);
  return ok(res, { liked: true, likesCount: video.likesCount + 1 });
});

const commentSchema = z.object({
  content: z.string().trim().min(1).max(500),
});

/** GET /api/short-videos/:id/comments */
shortVideosRouter.get("/:id/comments", optionalAuth, async (req, res) => {
  const videoId = req.params.id;
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 30)));
  const rows = await prisma.shortVideoComment.findMany({
    where: { videoId },
    orderBy: { createdAt: "desc" },
    take: limit,
    include: { user: true },
  });
  return ok(res, {
    comments: rows.map((c) => ({
      id: c.id,
      content: c.content,
      createdAt: c.createdAt.toISOString(),
      author: authorPayload(c.user),
    })),
  });
});

/** POST /api/short-videos/:id/comments */
shortVideosRouter.post("/:id/comments", requireAuth, async (req, res) => {
  const parsed = commentSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz yorum");
  }
  const videoId = req.params.id;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");

  const row = await prisma.$transaction(async (tx) => {
    const comment = await tx.shortVideoComment.create({
      data: {
        videoId,
        userId: req.userId!,
        content: parsed.data.content,
      },
      include: { user: true },
    });
    await tx.shortVideo.update({
      where: { id: videoId },
      data: { commentsCount: { increment: 1 } },
    });
    return comment;
  });

  return ok(
    res,
    {
      comment: {
        id: row.id,
        content: row.content,
        createdAt: row.createdAt.toISOString(),
        author: authorPayload(row.user),
      },
      commentsCount: video.commentsCount + 1,
    },
    201,
  );
});

/** POST /api/short-videos/:id/view — ≥3 sn izlendi (kullanıcı başına +1) */
shortVideosRouter.post("/:id/view", requireAuth, async (req, res) => {
  const videoId = req.params.id;
  const userId = req.userId!;
  const watchedSec = Number(req.body?.watchedSec ?? req.body?.seconds ?? 0);
  if (!Number.isFinite(watchedSec) || watchedSec < 3) {
    return ok(res, { counted: false, reason: "min_3_seconds" });
  }

  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");

  const existing = await prisma.shortVideoView.findUnique({
    where: { videoId_userId: { videoId, userId } },
  });
  if (existing) {
    return ok(res, { counted: false, viewsCount: video.viewsCount });
  }

  const updated = await prisma.$transaction(async (tx) => {
    await tx.shortVideoView.create({ data: { videoId, userId } });
    return tx.shortVideo.update({
      where: { id: videoId },
      data: { viewsCount: { increment: 1 } },
    });
  });

  return ok(res, { counted: true, viewsCount: updated.viewsCount });
});

/** DELETE /api/short-videos/:id — yalnızca sahibi */
shortVideosRouter.delete("/:id", requireAuth, async (req, res) => {
  const videoId = req.params.id;
  const userId = req.userId!;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");
  if (video.userId !== userId) {
    return fail(res, 403, "FORBIDDEN", "Yalnızca kendi videonuzu silebilirsiniz");
  }
  await prisma.shortVideo.delete({ where: { id: videoId } });
  return ok(res, { deleted: true });
});

/** GET /api/short-videos/user/:userId — profil grid */
shortVideosRouter.get("/user/:userId", optionalAuth, async (req, res) => {
  const userId = req.params.userId;
  const limit = Math.min(30, Math.max(1, Number(req.query.limit ?? 20)));
  const rows = await prisma.shortVideo.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: limit,
    include: { user: true },
  });
  return ok(res, { videos: rows.map((v) => videoPayload(v)) });
});
