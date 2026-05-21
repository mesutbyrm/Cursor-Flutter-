import { Router } from "express";
import { prisma } from "../lib/prisma";
import { fail, ok } from "../lib/response";
import { optionalAuth, requireAuth } from "../middleware/optionalAuth";
import { requireStaff } from "../middleware/requireStaff";
import { createNotification } from "../lib/notifications";

export const walletRouter = Router();

/** GET /api/user/credits — jeton + CFC (canlifal.com uyumlu) */
walletRouter.get("/user/credits", optionalAuth, async (req, res) => {
  if (!req.userId) {
    return ok(res, { credits: 0, coins: 0, jeton: 0, cfc: 0, balance: 0 });
  }
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  const jeton = user.coins;
  const cfc = user.cfcBalance;
  return ok(res, {
    credits: jeton,
    coins: jeton,
    jeton,
    cfc,
    cfcBalance: cfc,
    balance: jeton,
    role: user.role,
  });
});

/** GET /api/wallet — alternatif */
walletRouter.get("/wallet", optionalAuth, async (req, res) => {
  if (!req.userId) return ok(res, { balance: 0, jeton: 0, cfc: 0 });
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) return fail(res, 404, "NOT_FOUND", "Kullanıcı bulunamadı");
  return ok(res, {
    balance: user.coins,
    jeton: user.coins,
    cfc: user.cfcBalance,
    role: user.role,
  });
});

/** GET /api/jeton — paket listesi */
walletRouter.get("/jeton", async (_req, res) => {
  const packages = [
    { id: "p100", title: "100 Jeton", coins: 100, priceTry: 29.9, badge: "Popüler" },
    { id: "p500", title: "500 Jeton", coins: 500, priceTry: 129.9, badge: "En iyi değer" },
    { id: "p1000", title: "1000 Jeton", coins: 1000, priceTry: 229.9 },
    { id: "p5000", title: "5000 Jeton", coins: 5000, priceTry: 999.9, badge: "VIP" },
  ];
  return res.status(200).json({ packages, items: packages, data: packages });
});

/** GET /api/payment/config */
walletRouter.get("/payment/config", async (_req, res) => {
  const cfg = await prisma.paymentConfig.upsert({
    where: { id: "default" },
    create: {
      id: "default",
      whatsappNumber: process.env.PAYMENT_WHATSAPP ?? "905551234567",
      paparaAddress: process.env.PAYMENT_PAPARA ?? "canlifal@papara.com",
      bankIban: process.env.PAYMENT_IBAN ?? "TR00 0000 0000 0000 0000 0000 00",
      bankName: process.env.PAYMENT_BANK ?? "Ziraat Bankası",
      accountHolder: process.env.PAYMENT_HOLDER ?? "CanlıFal",
    },
    update: {},
  });
  return ok(res, cfg);
});

const paymentRequestSchema = {
  method: ["whatsapp", "papara", "havale"] as const,
};

/** POST /api/payment/requests */
walletRouter.post("/payment/requests", optionalAuth, async (req, res) => {
  const method = String(req.body?.method ?? "").toLowerCase();
  if (!paymentRequestSchema.method.includes(method as (typeof paymentRequestSchema.method)[number])) {
    return fail(res, 400, "VALIDATION_ERROR", "Geçersiz ödeme yöntemi");
  }

  const userName =
    String(req.body?.userName ?? req.body?.displayName ?? "Kullanıcı").slice(0, 64) ||
    "Kullanıcı";

  const row = await prisma.paymentRequest.create({
    data: {
      userId: req.userId ?? null,
      userName,
      method,
      packageId: req.body?.packageId?.toString(),
      packageTitle: req.body?.packageTitle?.toString(),
      amountTry: req.body?.amountTry != null ? Number(req.body.amountTry) : null,
      coins: Number(req.body?.coins ?? 0) || 0,
      note: req.body?.note?.toString()?.slice(0, 500),
    },
  });

  const methodLabel =
    method === "whatsapp" ? "WhatsApp" : method === "papara" ? "Papara" : "Havale/EFT";

  await createNotification({
    userId: req.userId ?? undefined,
    title: "Ödeme talebi alındı",
    body: `${userName} — ${methodLabel} · ${row.packageTitle ?? row.coins + " jeton"}`,
    type: "payment",
    targetPath: "/jeton-store",
    targetId: row.id,
  });

  const staff = await prisma.user.findMany({
    where: { role: { in: ["admin", "yonetici", "moderator", "destek", "yardim"] } },
    select: { id: true },
  });
  for (const s of staff) {
    await createNotification({
      userId: s.id,
      title: "Yeni ödeme talebi",
      body: `${userName} · ${methodLabel} · ${row.packageTitle ?? ""}`,
      type: "admin_payment",
      targetPath: "/admin/payments",
      targetId: row.id,
    });
  }

  return ok(res, row, 201);
});

/** GET /api/admin/notifications */
walletRouter.get(
  "/admin/notifications",
  requireAuth,
  requireStaff,
  async (_req, res) => {
    const rows = await prisma.appNotification.findMany({
      orderBy: { createdAt: "desc" },
      take: 100,
    });
    return ok(res, {
      items: rows.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        targetPath: n.targetPath,
        targetId: n.targetId,
        read: n.read,
        createdAt: n.createdAt.toISOString(),
      })),
    });
  },
);

/** GET /api/admin/payment-requests — personel */
walletRouter.get(
  "/admin/payment-requests",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const status = req.query.status as string | undefined;
    const rows = await prisma.paymentRequest.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: "desc" },
      take: 50,
    });
    return ok(res, { requests: rows });
  },
);
