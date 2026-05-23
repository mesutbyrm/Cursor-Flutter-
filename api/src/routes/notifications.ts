import { Router } from "express";
import { prisma } from "../lib/prisma";
import { ok } from "../lib/response";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import { requireStaff } from "../middleware/requireStaff";

function rowPayload(n: {
  id: string;
  title: string;
  body: string | null;
  type: string;
  targetPath: string | null;
  targetId: string | null;
  read: boolean;
  createdAt: Date;
}) {
  return {
    id: n.id,
    title: n.title,
    body: n.body,
    message: n.body,
    type: n.type,
    targetPath: n.targetPath,
    targetId: n.targetId,
    actionUrl: n.targetPath,
    read: n.read,
    isRead: n.read,
    createdAt: n.createdAt.toISOString(),
  };
}

export const notificationsRouter = Router();

/** GET /api/notifications */
notificationsRouter.get("/", optionalAuth, async (req, res) => {
  const userId = req.userId;
  const rows = await prisma.appNotification.findMany({
    where: userId
      ? { OR: [{ userId }, { userId: null }] }
      : { userId: null },
    orderBy: { createdAt: "desc" },
    take: 80,
  });
  return res.status(200).json({
    items: rows.map(rowPayload),
    notifications: rows.map(rowPayload),
    data: rows.map(rowPayload),
  });
});

/** PATCH /api/notifications/:id/read */
notificationsRouter.patch("/:id/read", optionalAuth, async (req, res) => {
  await prisma.appNotification.updateMany({
    where: { id: req.params.id },
    data: { read: true },
  });
  return ok(res, { read: true });
});
