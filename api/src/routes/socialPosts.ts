import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { requireAuth } from "../middleware/requireAuth";

function postPayload(p: {
  id: string;
  caption: string | null;
  mediaUrl: string | null;
  postType: string;
  likesCount: number;
  commentsCount: number;
  createdAt: Date;
  author: {
    id: string;
    email: string;
    displayName: string | null;
    username: string | null;
    avatarUrl: string | null;
  };
}) {
  return {
    id: p.id,
    caption: p.caption,
    text: p.caption,
    content: p.caption,
    mediaUrl: p.mediaUrl,
    imageUrl: p.mediaUrl,
    postType: p.postType,
    likesCount: p.likesCount,
    commentsCount: p.commentsCount,
    createdAt: p.createdAt.toISOString(),
    author: {
      id: p.author.id,
      userId: p.author.id,
      username: p.author.username ?? p.author.email.split("@")[0],
      displayName: p.author.displayName ?? p.author.email.split("@")[0],
      avatarUrl: p.author.avatarUrl,
    },
  };
}

const createSchema = z.object({
  caption: z.string().max(2200).optional(),
  text: z.string().max(2200).optional(),
  content: z.string().max(2200).optional(),
  mediaUrl: z.string().url().optional(),
  imageUrl: z.string().url().optional(),
  postType: z.enum(["text", "image"]).optional(),
});

export const socialPostsRouter = Router();

socialPostsRouter.get("/posts", async (req, res) => {
  const page = Math.max(1, Number(req.query.page ?? 1));
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 20)));
  const skip = (page - 1) * limit;

  const [total, rows] = await Promise.all([
    prisma.socialPost.count(),
    prisma.socialPost.findMany({
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
      include: { author: true },
    }),
  ]);

  const totalPages = Math.max(1, Math.ceil(total / limit));
  return ok(res, {
    posts: rows.map(postPayload),
    pagination: { page, limit, totalPages, total },
  });
});

socialPostsRouter.post("/posts", requireAuth, async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz paylaşım", parsed.error.flatten());
  }
  const caption =
    parsed.data.caption?.trim() ||
    parsed.data.text?.trim() ||
    parsed.data.content?.trim() ||
    "";
  const mediaUrl = parsed.data.mediaUrl ?? parsed.data.imageUrl ?? null;
  if (!caption && !mediaUrl) {
    return fail(res, 400, "VALIDATION_ERROR", "Açıklama veya görsel gerekli");
  }

  const postType = parsed.data.postType ?? (mediaUrl ? "image" : "text");
  const author = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!author) {
    return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  }

  const created = await prisma.socialPost.create({
    data: {
      authorId: author.id,
      caption: caption || null,
      mediaUrl,
      postType,
    },
    include: { author: true },
  });

  return ok(res, { post: postPayload(created) }, 201);
});
