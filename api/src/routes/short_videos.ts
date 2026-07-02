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
import { uploadShortMedia, getShortMediaObject, storageKeyFromPublicUrl } from "../lib/r2Storage";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import { shortsRecordEngagement } from "../lib/redis/shortsTrending";

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
    sharesCount?: number;
    savesCount?: number;
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
  extras?: { likedByMe?: boolean; viewedByMe?: boolean; savedByMe?: boolean },
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
    sharesCount: v.sharesCount ?? 0,
    savesCount: v.savesCount ?? 0,
    durationSec: v.durationSec,
    createdAt: v.createdAt.toISOString(),
    author: authorPayload(v.user),
    likedByMe: extras?.likedByMe ?? false,
    viewedByMe: extras?.viewedByMe ?? false,
    savedByMe: extras?.savedByMe ?? false,
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

/** GET /api/short-videos/viewed/me — izlediğim videolar */
shortVideosRouter.get("/viewed/me", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const limit = Math.min(30, Math.max(1, Number(req.query.limit ?? 20)));
  const cursor =
    typeof req.query.cursor === "string" && req.query.cursor.trim()
      ? req.query.cursor.trim()
      : undefined;

  const views = await prisma.shortVideoView.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    include: {
      video: { include: { user: true } },
    },
  });

  const hasMore = views.length > limit;
  const page = hasMore ? views.slice(0, limit) : views;
  const videos = page
    .map((v) => v.video)
    .filter(Boolean)
    .map((v) => videoPayload(v, { viewedByMe: true }));

  return ok(res, {
    videos,
    nextCursor: hasMore ? page[page.length - 1]?.id : null,
    hasMore,
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

/** GET /api/short-videos/:id — tek video */
shortVideosRouter.get("/:id", optionalAuth, async (req, res) => {
  const videoId = req.params.id;
  const userId = req.userId;
  const video = await prisma.shortVideo.findUnique({
    where: { id: videoId },
    include: { user: true },
  });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");
  let likedByMe = false;
  let savedByMe = false;
  if (userId) {
    const [like, save] = await Promise.all([
      prisma.shortVideoLike.findUnique({
        where: { videoId_userId: { videoId, userId } },
      }),
      prisma.shortVideoSave.findUnique({
        where: { videoId_userId: { videoId, userId } },
      }),
    ]);
    likedByMe = !!like;
    savedByMe = !!save;
  }
  return ok(res, {
    video: {
      ...videoPayload(video, { likedByMe }),
      savedByMe,
      sharesCount: video.sharesCount,
      savesCount: video.savesCount,
    },
  });
});

/** POST /api/short-videos/:id/save — kaydet toggle */
shortVideosRouter.post("/:id/save", requireAuth, async (req, res) => {
  const videoId = req.params.id;
  const userId = req.userId!;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");

  const existing = await prisma.shortVideoSave.findUnique({
    where: { videoId_userId: { videoId, userId } },
  });

  if (existing) {
    await prisma.$transaction([
      prisma.shortVideoSave.delete({ where: { id: existing.id } }),
      prisma.shortVideo.update({
        where: { id: videoId },
        data: { savesCount: { decrement: 1 } },
      }),
    ]);
    return ok(res, {
      saved: false,
      savesCount: Math.max(0, video.savesCount - 1),
    });
  }

  await prisma.$transaction([
    prisma.shortVideoSave.create({ data: { videoId, userId } }),
    prisma.shortVideo.update({
      where: { id: videoId },
      data: { savesCount: { increment: 1 } },
    }),
  ]);
  return ok(res, { saved: true, savesCount: video.savesCount + 1 });
});

/** POST /api/short-videos/:id/share — paylaşım sayacı */
shortVideosRouter.post("/:id/share", requireAuth, async (req, res) => {
  const videoId = req.params.id;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");
  const updated = await prisma.shortVideo.update({
    where: { id: videoId },
    data: { sharesCount: { increment: 1 } },
  });
  void shortsRecordEngagement({ videoId, shares: 1 });
  return ok(res, { sharesCount: updated.sharesCount });
});

/** GET /api/short-videos/profile/:userId — profil istatistikleri */
shortVideosRouter.get("/profile/:userId", optionalAuth, async (req, res) => {
  const userId = req.params.userId;
  const viewerId = req.userId;
  const [videosCount, agg, followerCount, followingCount] = await Promise.all([
    prisma.shortVideo.count({ where: { userId } }),
    prisma.shortVideo.aggregate({
      where: { userId },
      _sum: { likesCount: true, viewsCount: true },
    }),
    prisma.follow.count({ where: { followingId: userId } }).catch(() => 0),
    prisma.follow.count({ where: { followerId: userId } }).catch(() => 0),
  ]);
  let isFollowing = false;
  if (viewerId && viewerId !== userId) {
    const f = await prisma.follow
      .findFirst({
        where: { followerId: viewerId, followingId: userId },
      })
      .catch(() => null);
    isFollowing = !!f;
  }
  return ok(res, {
    videosCount,
    totalLikes: agg._sum.likesCount ?? 0,
    totalViews: agg._sum.viewsCount ?? 0,
    followersCount: followerCount,
    followingCount: followingCount,
    isFollowing,
  });
});

/** GET /api/short-videos/:id/stream — CDN 404 olduğunda R2 üzerinden oynatma */
shortVideosRouter.get("/:id/stream", optionalAuth, async (req, res) => {
  const videoId = req.params.id;
  const video = await prisma.shortVideo.findUnique({ where: { id: videoId } });
  if (!video) return fail(res, 404, "NOT_FOUND", "Video bulunamadı");

  const key = storageKeyFromPublicUrl(video.videoUrl);
  if (!key) return fail(res, 404, "NOT_FOUND", "Video dosyası bulunamadı");

  const range = typeof req.headers.range === "string" ? req.headers.range : undefined;
  const obj = await getShortMediaObject(key, range);
  if (!obj) return fail(res, 404, "NOT_FOUND", "Video dosyası bulunamadı");

  res.setHeader("Content-Type", obj.contentType);
  res.setHeader("Cache-Control", "public, max-age=3600");
  res.setHeader("Accept-Ranges", "bytes");
  if (obj.isPartial && obj.contentRange) {
    res.statusCode = 206;
    res.setHeader("Content-Range", obj.contentRange);
  }
  if (obj.contentLength != null) {
    res.setHeader("Content-Length", String(obj.contentLength));
  }

  obj.body.on("error", () => {
    if (!res.headersSent) res.statusCode = 500;
    res.end();
  });
  res.on("close", () => {
    const b = obj.body as NodeJS.ReadableStream & { destroy?: () => void };
    if (typeof b.destroy === "function") b.destroy();
  });
  obj.body.pipe(res);
});

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
  void shortsRecordEngagement({ videoId, likes: 1 });
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

  void shortsRecordEngagement({
    videoId,
    views: 1,
    watchTimeMs: watchedSec * 1000,
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
  const tab = typeof req.query.tab === "string" ? req.query.tab : "videos";
  const limit = Math.min(30, Math.max(1, Number(req.query.limit ?? 20)));
  const viewerId = req.userId;

  if (tab === "liked" && viewerId) {
    const likes = await prisma.shortVideoLike.findMany({
      where: { userId: viewerId },
      orderBy: { createdAt: "desc" },
      take: limit,
      include: { video: { include: { user: true } } },
    });
    return ok(res, {
      videos: likes.map((l) => videoPayload(l.video, { likedByMe: true })),
    });
  }

  if (tab === "saved" && viewerId) {
    const saves = await prisma.shortVideoSave.findMany({
      where: { userId: viewerId },
      orderBy: { createdAt: "desc" },
      take: limit,
      include: { video: { include: { user: true } } },
    });
    return ok(res, {
      videos: saves.map((s) => videoPayload(s.video, { savedByMe: true })),
    });
  }

  const rows = await prisma.shortVideo.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: limit,
    include: { user: true },
  });
  return ok(res, { videos: rows.map((v) => videoPayload(v)) });
});
