import { Router, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth } from "../middleware/requireAuth";
import { fail, ok } from "../lib/response";

const prisma = new PrismaClient();
const router = Router();

// GET /api/subscriptions/plans
router.get("/plans", async (_req: Request, res: Response) => {
  try {
    const plans = await prisma.subscriptionPlan.findMany({
      orderBy: { monthlyPrice: "asc" },
    });

    res.json(ok({
      plans: plans.map(p => ({
        planId: p.planId,
        name: p.name,
        description: p.description,
        monthlyPrice: p.monthlyPrice,
        yearlyPrice: p.yearlyPrice,
        yearlyDiscount: p.yearlyDiscount,
        features: p.features,
        limits: p.limits,
      })),
    }));
  } catch (error: any) {
    res.status(500).json(fail("Planlar alınamadı", error.message));
  }
});

// GET /api/subscriptions/current
router.get("/current", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.json(ok({ subscription: null }));
    }

    res.json(ok({
      subscription: {
        subscriptionId: subscription.id,
        userId: subscription.userId,
        planId: subscription.planId,
        status: subscription.status,
        currentPeriodStart: subscription.currentPeriodStart,
        currentPeriodEnd: subscription.currentPeriodEnd,
        billingCycle: subscription.billingCycle,
        price: subscription.price,
        autoRenew: subscription.autoRenew,
        nextBillingDate: subscription.currentPeriodEnd,
      },
    }));
  } catch (error: any) {
    res.status(500).json(fail("Abonelik bilgisi alınamadı", error.message));
  }
});

// POST /api/subscriptions/create
router.post("/create", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { planId, billingCycle = "monthly", paymentMethodId, couponCode } = req.body;

    // Validate plan exists
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { planId },
    });

    if (!plan) {
      return res.status(404).json(fail("Plan bulunamadı"));
    }

    // Check for existing subscription
    const existing = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (existing) {
      return res.status(400).json(fail("Zaten aktif bir aboneliğiniz var"));
    }

    const price = billingCycle === "monthly" ? plan.monthlyPrice : plan.yearlyPrice;
    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setMonth(periodEnd.getMonth() + (billingCycle === "monthly" ? 1 : 12));

    const subscription = await prisma.subscription.create({
      data: {
        userId,
        planId,
        billingCycle,
        status: "active",
        currentPeriodStart: now,
        currentPeriodEnd: periodEnd,
        price,
        paymentMethodId,
      },
    });

    res.status(201).json(ok({
      subscriptionId: subscription.id,
      status: subscription.status,
      planId: subscription.planId,
      currentPeriodEnd: subscription.currentPeriodEnd,
      activatedAt: subscription.createdAt,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Abonelik oluşturulamadı", error.message));
  }
});

// PUT /api/subscriptions/current
router.put("/current", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { planId, billingCycle } = req.body;

    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.status(404).json(fail("Abonelik bulunamadı"));
    }

    const plan = await prisma.subscriptionPlan.findUnique({
      where: { planId },
    });

    if (!plan) {
      return res.status(404).json(fail("Plan bulunamadı"));
    }

    const price = billingCycle === "monthly" ? plan.monthlyPrice : plan.yearlyPrice;
    const periodEnd = new Date();
    periodEnd.setMonth(periodEnd.getMonth() + (billingCycle === "monthly" ? 1 : 12));

    const updated = await prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        planId,
        billingCycle,
        price,
        currentPeriodEnd: periodEnd,
      },
    });

    res.json(ok({
      subscriptionId: updated.id,
      status: updated.status,
      planId: updated.planId,
      price: updated.price,
      billingCycle: updated.billingCycle,
      newPeriodEnd: updated.currentPeriodEnd,
    }));
  } catch (error: any) {
    res.status(500).json(fail("Abonelik güncellenemedi", error.message));
  }
});

// DELETE /api/subscriptions/current
router.delete("/current", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    if (!userId) return res.status(401).json(fail("Kimlik doğrulaması başarısız"));

    const { reason, feedback } = req.body;

    const subscription = await prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      return res.status(404).json(fail("Abonelik bulunamadı"));
    }

    const updated = await prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: "cancelled",
        cancelledAt: new Date(),
      },
    });

    res.json(ok({
      subscriptionId: updated.id,
      status: updated.status,
      cancelledAt: updated.cancelledAt,
      accessUntil: updated.currentPeriodEnd,
      retentionOffer: {
        discount: 0.5,
        validUntil: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    }));
  } catch (error: any) {
    res.status(500).json(fail("Abonelik iptal edilemedi", error.message));
  }
});

export const subscriptionsRouter = router;
