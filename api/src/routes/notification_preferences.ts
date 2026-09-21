import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";

const prisma = new PrismaClient();
const router = Router();

// GET /api/notifications
router.get("/", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const offset = parseInt(req.query.offset as string) || 0;
    const type = (req.query.type as string) || "all";
    const filter = (req.query.filter as string) || "all";

    let where: any = { userId };
    if (type !== "all") where.type = type;
    if (filter === "unread") where.read = false;

    const notifications = await prisma.notification.findMany({
      where,
      orderBy: { createdAt: "desc" },
      take: limit,
      skip: offset,
    });

    const total = await prisma.notification.count({ where });
    const unreadCount = await prisma.notification.count({
      where: { userId, read: false },
    });

    res.json(ok({
      notifications: notifications.map(n => ({
        notificationId: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        icon: n.icon,
        actionUrl: n.actionUrl,
        read: n.read,
        createdAt: n.createdAt,
        expiresAt: n.expiresAt,
      })),
      total,
      unreadCount,
      hasMore: offset + limit < total,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Bildirimler alınamadı", error.message));
  }
});

// GET /api/notifications/preferences
router.get("/preferences", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    let prefs = await prisma.notificationPreference.findUnique({
      where: { userId },
    });

    if (!prefs) {
      prefs = await prisma.notificationPreference.create({
        data: { userId },
      });
    }

    res.json(ok({
      preferences: {
        dailyReminder: {
          enabled: prefs.dailyReminderEnabled,
          time: prefs.dailyReminderTime,
          timezone: prefs.dailyReminderTimezone,
        },
        streakReminder: {
          enabled: prefs.streakReminderEnabled,
          time: prefs.streakReminderTime,
        },
        achievements: {
          enabled: prefs.achievementsEnabled,
        },
        social: {
          enabled: prefs.socialEnabled,
          likes: prefs.socialLikesEnabled,
          comments: prefs.socialCommentsEnabled,
          shares: prefs.socialSharesEnabled,
        },
        features: {
          enabled: prefs.featuresEnabled,
        },
        quiet_hours: {
          enabled: prefs.quietHoursEnabled,
          startTime: prefs.quietHoursStart,
          endTime: prefs.quietHoursEnd,
        },
        channels: {
          push: prefs.pushEnabled,
          email: prefs.emailEnabled,
          inApp: prefs.inAppEnabled,
        },
      },
    }));
  } catch (error: any) {
    res.status(500).json(fail("Tercihler alınamadı", error.message));
  }
});

// PUT /api/notifications/preferences
router.put("/preferences", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const {
      dailyReminder,
      streakReminder,
      achievements,
      social,
      features,
      quiet_hours,
      channels,
    } = req.body;

    let prefs = await prisma.notificationPreference.findUnique({
      where: { userId },
    });

    if (!prefs) {
      prefs = await prisma.notificationPreference.create({
        data: { userId },
      });
    }

    prefs = await prisma.notificationPreference.update({
      where: { id: prefs.id },
      data: {
        ...(dailyReminder && {
          dailyReminderEnabled: dailyReminder.enabled,
          dailyReminderTime: dailyReminder.time,
          dailyReminderTimezone: dailyReminder.timezone,
        }),
        ...(streakReminder && {
          streakReminderEnabled: streakReminder.enabled,
          streakReminderTime: streakReminder.time,
        }),
        ...(achievements && {
          achievementsEnabled: achievements.enabled,
        }),
        ...(social && {
          socialEnabled: social.enabled,
          socialLikesEnabled: social.likes,
          socialCommentsEnabled: social.comments,
          socialSharesEnabled: social.shares,
        }),
        ...(features && {
          featuresEnabled: features.enabled,
        }),
        ...(quiet_hours && {
          quietHoursEnabled: quiet_hours.enabled,
          quietHoursStart: quiet_hours.startTime,
          quietHoursEnd: quiet_hours.endTime,
        }),
        ...(channels && {
          pushEnabled: channels.push,
          emailEnabled: channels.email,
          inAppEnabled: channels.inApp,
        }),
      },
    });

    res.json(ok({
      success: true,
      updatedAt: new Date(),
    }));
  } catch (error: any) {
    res.status(500).json(fail("Tercihler güncellenemedi", error.message));
  }
});

// PUT /api/notifications/{notificationId}/read
router.put("/:notificationId/read", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { notificationId } = req.params;
    const { read } = req.body;

    const notif = await prisma.notification.update({
      where: { id: notificationId },
      data: {
        read,
        readAt: read ? new Date() : null,
      },
    });

    res.json(ok({
      notificationId: notif.id,
      read: notif.read,
      readAt: notif.readAt,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Bildirim güncellenemedi", error.message));
  }
});

// DELETE /api/notifications/{notificationId}
router.delete("/:notificationId", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { notificationId } = req.params;

    const notif = await prisma.notification.delete({
      where: { id: notificationId },
    });

    res.json(ok({
      success: true,
      notificationId: notif.id,
      deletedAt: new Date(),
    }));
  } catch (error: any) {
    res.status(500).json(fail("Bildirim silinemedi", error.message));
  }
});

// POST /api/notifications/test
router.post("/test", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { type = "daily_reminder", channel = "push" } = req.body;

    // Create test notification
    await prisma.notification.create({
      data: {
        userId,
        type,
        title: "Test Bildirimi",
        message: "Bu bir test bildirimidir",
        icon: "📬",
        channels: [channel],
      },
    });

    res.json(ok({
      success: true,
      sentAt: new Date(),
      message: "Test bildirimi gönderildi",
    }));
  } catch (error: any) {
    res.status(500).json(fail("Test bildirimi gönderilemedi", error.message));
  }
});

export const notificationPreferencesRouter = router;
