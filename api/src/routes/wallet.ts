import { Router } from "express";
import { prisma } from "../lib/prisma";
import { jsonError } from "../lib/jsonError";
import { createNotification } from "../lib/notifications";
import { requireAuth } from "../middleware/requireAuth";
import { requireStaff, isStaffRole } from "../middleware/requireStaff";

export const walletRouter = Router();

const PAYMENT_METHODS = new Set(["whatsapp", "papara", "bank_transfer"]);

async function getOrCreateCfcSettings() {
  return prisma.cfcSettings.upsert({
    where: { id: "default" },
    create: {
      id: "default",
      cfcWhatsappNumber:
        process.env.CFC_WHATSAPP ??
        process.env.PAYMENT_WHATSAPP ??
        "05327170173",
      cfcPaparaAddress:
        process.env.CFC_PAPARA ?? process.env.PAYMENT_PAPARA ?? "1555517633",
      cfcBankName:
        process.env.CFC_BANK ?? process.env.PAYMENT_BANK ?? "Garanti Bankası",
      cfcBankIban:
        process.env.CFC_IBAN ??
        process.env.PAYMENT_IBAN ??
        "TR94 0006 2000 0010 0006 8126 92",
      cfcBankAccountHolder:
        process.env.CFC_HOLDER ?? process.env.PAYMENT_HOLDER ?? "Mesut bayram",
      cfcTlRate: Number(process.env.CFC_TL_RATE ?? "1") || 1,
      cfcMinAmount: Number(process.env.CFC_MIN_AMOUNT ?? "10") || 10,
    },
    update: {},
  });
}

function paymentConfigPayload(s: Awaited<ReturnType<typeof getOrCreateCfcSettings>>) {
  return {
    whatsappNumber: s.cfcWhatsappNumber,
    paparaAddress: s.cfcPaparaAddress,
    bankName: s.cfcBankName ?? "",
    bankIban: s.cfcBankIban,
    bankAccountHolder: s.cfcBankAccountHolder ?? "",
    accountHolder: s.cfcBankAccountHolder ?? "",
    cfcRate: s.cfcTlRate,
    minCfcAmount: s.cfcMinAmount,
  };
}

function cfcSettingsPayload(s: Awaited<ReturnType<typeof getOrCreateCfcSettings>>) {
  return {
    cfc_whatsapp_number: s.cfcWhatsappNumber,
    cfc_papara_address: s.cfcPaparaAddress,
    cfc_bank_name: s.cfcBankName ?? "",
    cfc_bank_iban: s.cfcBankIban,
    cfc_bank_account_holder: s.cfcBankAccountHolder ?? "",
    cfc_tl_rate: String(s.cfcTlRate),
    cfc_min_amount: String(s.cfcMinAmount),
  };
}

function requestPayload(row: {
  id: string;
  userId: string;
  requestType: string;
  amount: number;
  method: string;
  packageId: string | null;
  packageTitle: string | null;
  coins: number | null;
  priceTry: number | null;
  senderInfo: string | null;
  notes: string | null;
  status: string;
  reviewedBy: string | null;
  reviewNote: string | null;
  createdAt: Date;
  updatedAt: Date;
  user?: {
    id: string;
    displayName: string | null;
    username: string | null;
    email: string;
    avatarUrl: string | null;
  };
}) {
  return {
    id: row.id,
    userId: row.userId,
    requestType: row.requestType,
    amount: row.amount,
    method: row.method,
    packageId: row.packageId ?? undefined,
    packageTitle: row.packageTitle ?? undefined,
    coins: row.coins ?? undefined,
    priceTry: row.priceTry ?? undefined,
    senderInfo: row.senderInfo,
    notes: row.notes,
    status: row.status,
    reviewedBy: row.reviewedBy,
    reviewNote: row.reviewNote,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    ...(row.user
      ? {
          user: {
            id: row.user.id,
            name: row.user.displayName ?? row.user.username ?? "Kullanıcı",
            username: row.user.username,
            email: row.user.email,
            image: row.user.avatarUrl,
          },
        }
      : {}),
  };
}

/** GET /api/user/credits */
walletRouter.get("/user/credits", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) return jsonError(res, 404, "Kullanıcı bulunamadı");

  return res.status(200).json({
    credits: user.coins,
    jetonBalance: user.coins,
    cfcBalance: user.cfcBalance,
    jetonTlRate: Number(process.env.JETON_TL_RATE ?? "0.5") || 0.5,
    withdrawalLimit: 0,
    membership: user.membership,
    membershipExpiresAt: user.membershipExpiresAt?.toISOString() ?? null,
    role: user.role,
    jeton: user.coins,
    cfc: user.cfcBalance,
  });
});

/** GET /api/wallet — geriye dönük */
walletRouter.get("/wallet", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) return jsonError(res, 404, "Kullanıcı bulunamadı");
  return res.status(200).json({
    balance: user.coins,
    jeton: user.coins,
    jetonBalance: user.coins,
    cfc: user.cfcBalance,
    cfcBalance: user.cfcBalance,
    role: user.role,
  });
});

/** GET /api/jeton — jeton paketleri (ayrı akış) */
walletRouter.get("/jeton", async (_req, res) => {
  const packages = [
    { id: "p100", title: "100 Jeton", coins: 100, priceTry: 29.9, badge: "Popüler" },
    { id: "p500", title: "500 Jeton", coins: 500, priceTry: 129.9, badge: "En iyi değer" },
    { id: "p1000", title: "1000 Jeton", coins: 1000, priceTry: 229.9 },
    { id: "p5000", title: "5000 Jeton", coins: 5000, priceTry: 999.9, badge: "VIP" },
  ];
  return res.status(200).json({ packages, items: packages, data: packages });
});

/** GET /api/payment/config — CFC yükleme bilgileri */
walletRouter.get("/payment/config", requireAuth, async (_req, res) => {
  const s = await getOrCreateCfcSettings();
  return res.status(200).json(paymentConfigPayload(s));
});

/** POST /api/payment/requests — CFC veya jeton yükleme talebi */
walletRouter.post("/payment/requests", requireAuth, async (req, res) => {
  const userId = req.userId!;
  const method = String(req.body?.method ?? "").toLowerCase();
  if (!PAYMENT_METHODS.has(method)) {
    return jsonError(res, 400, "Geçersiz ödeme yöntemi");
  }

  const reqType = String(req.body?.requestType ?? req.body?.type ?? "")
    .toLowerCase()
    .trim();
  const isJeton =
    reqType === "jeton" ||
    req.body?.packageId != null ||
    req.body?.coins != null ||
    (reqType === "jeton" && req.body?.amount != null);

  let amount: number;
  let requestType = "cfc";
  let packageId: string | null = null;
  let packageTitle: string | null = null;
  let coins: number | null = null;
  let priceTry: number | null = null;

  if (isJeton) {
    requestType = "jeton";
    coins = Math.floor(Number(req.body?.coins ?? req.body?.amount ?? 0));
    if (!Number.isFinite(coins) || coins < 1) {
      return jsonError(res, 400, "Geçersiz jeton miktarı");
    }
    amount = coins;
    packageId = req.body?.packageId?.toString()?.slice(0, 64) ?? null;
    packageTitle =
      req.body?.packageTitle?.toString()?.slice(0, 128) ??
      (coins > 0 ? `${coins} Jeton` : null);
    const pt = Number(req.body?.priceTry);
    priceTry = Number.isFinite(pt) ? pt : null;
  } else {
    amount = Math.floor(Number(req.body?.amount));
    if (!Number.isFinite(amount) || amount < 1) {
      return jsonError(res, 400, "Geçersiz miktar");
    }
    const settings = await getOrCreateCfcSettings();
    if (amount < settings.cfcMinAmount) {
      return jsonError(res, 400, `Minimum ${settings.cfcMinAmount} CFC yüklenebilir`);
    }
  }

  const pending = await prisma.cfcPaymentRequest.findFirst({
    where: { userId, status: "pending" },
  });
  if (pending) {
    return jsonError(res, 400, "Zaten bekleyen bir ödeme talebiniz var");
  }

  const row = await prisma.cfcPaymentRequest.create({
    data: {
      userId,
      requestType,
      amount,
      method,
      packageId,
      packageTitle,
      coins,
      priceTry,
      senderInfo: req.body?.senderInfo?.toString()?.slice(0, 128) ?? null,
      notes: req.body?.notes?.toString()?.slice(0, 500) ?? null,
    },
  });

  const notifData = {
    paymentRequestId: row.id,
    amount: row.amount,
    method: row.method,
    requestType: row.requestType,
    packageId: row.packageId,
    coins: row.coins,
  };

  const userTitle =
    requestType === "jeton"
      ? "Jeton yükleme talebi alındı"
      : "CFC yükleme talebi alındı";
  const userBody =
    requestType === "jeton"
      ? `${row.packageTitle ?? row.amount + " jeton"} · ${method}`
      : `${row.amount} CFC · ${method}`;
  const userPath = requestType === "jeton" ? "/jeton-yukle" : "/cfc-store";
  const notifType =
    requestType === "jeton" ? "jeton_payment_request" : "cfc_payment_request";

  await createNotification({
    userId,
    title: userTitle,
    body: userBody,
    type: notifType,
    data: notifData,
    targetPath: userPath,
    targetId: row.id,
  });

  const staff = await prisma.user.findMany({
    where: { role: { in: ["admin", "yonetici", "moderator", "destek", "yardim"] } },
    select: { id: true },
  });
  const staffTitle =
    requestType === "jeton"
      ? "Ödeme yapıldı — Jeton yükleme talebi"
      : "Ödeme yapıldı — CFC yükleme talebi";
  for (const s of staff) {
    await createNotification({
      userId: s.id,
      title: staffTitle,
      body: userBody,
      type: notifType,
      data: notifData,
      targetPath: "/admin",
      targetId: row.id,
    });
  }

  return res.status(201).json(requestPayload(row));
});

/** GET /api/payment/requests — kullanıcının talepleri */
walletRouter.get("/payment/requests", requireAuth, async (req, res) => {
  const rows = await prisma.cfcPaymentRequest.findMany({
    where: { userId: req.userId! },
    orderBy: { createdAt: "desc" },
    take: 50,
  });
  return res.status(200).json(rows.map((r) => requestPayload(r)));
});

/** GET /api/admin/cfc-payment-requests */
walletRouter.get(
  "/admin/cfc-payment-requests",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const statusQ = String(req.query.status ?? "all");
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
    const skip = (page - 1) * limit;

    const where =
      statusQ === "all" || !statusQ
        ? undefined
        : { status: statusQ };

    const [total, rows] = await Promise.all([
      prisma.cfcPaymentRequest.count({ where }),
      prisma.cfcPaymentRequest.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              displayName: true,
              username: true,
              email: true,
              avatarUrl: true,
            },
          },
        },
      }),
    ]);

    return res.status(200).json({
      requests: rows.map((r) => requestPayload(r)),
      total,
      page,
      totalPages: Math.max(1, Math.ceil(total / limit)),
    });
  },
);

/** PATCH /api/admin/cfc-payment-requests */
walletRouter.patch(
  "/admin/cfc-payment-requests",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const requestId = req.body?.requestId?.toString();
    const action = req.body?.action?.toString();
    const reviewNote = req.body?.reviewNote?.toString()?.slice(0, 500);

    if (!requestId || !action) {
      return jsonError(res, 400, "Geçersiz istek");
    }

    const row = await prisma.cfcPaymentRequest.findUnique({
      where: { id: requestId },
    });
    if (!row) return jsonError(res, 404, "Talep bulunamadı");
    if (row.status !== "pending") {
      return jsonError(res, 400, "Bu talep zaten işlenmiş");
    }

    const isJeton = row.requestType === "jeton";

    if (action === "approve") {
      await prisma.$transaction([
        prisma.cfcPaymentRequest.update({
          where: { id: requestId },
          data: {
            status: "approved",
            reviewedBy: req.userId!,
            reviewNote: reviewNote ?? "Onaylandı",
          },
        }),
        prisma.user.update({
          where: { id: row.userId },
          data: isJeton
            ? { coins: { increment: row.coins ?? row.amount } }
            : { cfcBalance: { increment: row.amount } },
        }),
      ]);

      await createNotification({
        userId: row.userId,
        title: isJeton ? "Jeton Yükleme Onaylandı" : "CFC Yükleme Onaylandı",
        body: isJeton
          ? `${row.coins ?? row.amount} jeton hesabınıza eklendi.`
          : `${row.amount} CFC hesabınıza eklendi.`,
        type: isJeton ? "jeton_payment_approved" : "cfc_payment_approved",
        data: { paymentRequestId: row.id, amount: row.amount, method: row.method },
        targetPath: isJeton ? "/jeton-yukle" : "/cfc-store",
        targetId: row.id,
      });
    } else if (action === "reject") {
      await prisma.cfcPaymentRequest.update({
        where: { id: requestId },
        data: {
          status: "rejected",
          reviewedBy: req.userId!,
          reviewNote: reviewNote ?? null,
        },
      });

      await createNotification({
        userId: row.userId,
        title: isJeton ? "Jeton Yükleme Reddedildi" : "CFC Yükleme Reddedildi",
        body: reviewNote ?? "Talebiniz reddedildi.",
        type: isJeton ? "jeton_payment_rejected" : "cfc_payment_rejected",
        data: { paymentRequestId: row.id, amount: row.amount, method: row.method },
        targetPath: isJeton ? "/jeton-yukle" : "/cfc-store",
        targetId: row.id,
      });
    } else {
      return jsonError(res, 400, "Geçersiz istek");
    }

    const updated = await prisma.cfcPaymentRequest.findUnique({
      where: { id: requestId },
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            username: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
    });
    return res.status(200).json(requestPayload(updated!));
  },
);

/** GET /api/admin/cfc-settings */
walletRouter.get("/admin/cfc-settings", requireAuth, requireStaff, async (_req, res) => {
  const s = await getOrCreateCfcSettings();
  return res.status(200).json(cfcSettingsPayload(s));
});

/** POST /api/admin/cfc-settings */
walletRouter.post("/admin/cfc-settings", requireAuth, requireStaff, async (req, res) => {
  const b = req.body ?? {};
  await prisma.cfcSettings.upsert({
    where: { id: "default" },
    create: { id: "default" },
    update: {
      ...(b.cfc_whatsapp_number != null
        ? { cfcWhatsappNumber: String(b.cfc_whatsapp_number) }
        : {}),
      ...(b.cfc_papara_address != null
        ? { cfcPaparaAddress: String(b.cfc_papara_address) }
        : {}),
      ...(b.cfc_bank_name != null ? { cfcBankName: String(b.cfc_bank_name) } : {}),
      ...(b.cfc_bank_iban != null ? { cfcBankIban: String(b.cfc_bank_iban) } : {}),
      ...(b.cfc_bank_account_holder != null
        ? { cfcBankAccountHolder: String(b.cfc_bank_account_holder) }
        : {}),
      ...(b.cfc_tl_rate != null
        ? { cfcTlRate: Number(b.cfc_tl_rate) || 1 }
        : {}),
      ...(b.cfc_min_amount != null
        ? { cfcMinAmount: Number(b.cfc_min_amount) || 10 }
        : {}),
    },
  });
  return res.status(200).json({ success: true });
});

/** GET /api/admin/payment-requests — eski yol (uyumluluk) */
walletRouter.get("/admin/payment-requests", requireAuth, requireStaff, async (req, res) => {
  const statusQ = String(req.query.status ?? "pending");
  const rows = await prisma.cfcPaymentRequest.findMany({
    where: statusQ === "all" ? undefined : { status: statusQ },
    orderBy: { createdAt: "desc" },
    take: 50,
    include: {
      user: {
        select: {
          id: true,
          displayName: true,
          username: true,
          email: true,
          avatarUrl: true,
        },
      },
    },
  });
  return res.status(200).json({
    success: true,
    data: { requests: rows.map((r) => requestPayload(r)) },
  });
});

const PAYMENT_NOTIF_TYPES = [
  "cfc_payment_request",
  "jeton_payment_request",
  "cfc_payment_approved",
  "cfc_payment_rejected",
  "jeton_payment_approved",
  "jeton_payment_rejected",
] as const;

/** GET /api/admin/notifications — staff hesabına düşen bildirimler */
walletRouter.get("/admin/notifications", requireAuth, requireStaff, async (req, res) => {
  const userId = req.userId!;
  const paymentOnly =
    req.query.payment === "1" || req.query.type === "payment";

  const rows = await prisma.appNotification.findMany({
    where: paymentOnly
      ? { userId, type: { in: [...PAYMENT_NOTIF_TYPES] } }
      : { userId },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
  return res.status(200).json({
    items: rows.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      type: n.type,
      data: n.data,
      targetPath: n.targetPath,
      targetId: n.targetId,
      read: n.read,
      createdAt: n.createdAt.toISOString(),
    })),
    notifications: rows.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      type: n.type,
      read: n.read,
      createdAt: n.createdAt.toISOString(),
    })),
  });
});

const MEMBERSHIP_PACKAGES = [
  {
    id: "basic",
    title: "Basic",
    durationDays: 30,
    priceJeton: 100,
    bonusJeton: 100,
    falDiscountPercent: 10,
    tierOrder: 1,
  },
  {
    id: "premium",
    title: "Premium",
    durationDays: 30,
    priceJeton: 250,
    bonusJeton: 250,
    falDiscountPercent: 20,
    tierOrder: 2,
  },
  {
    id: "gold",
    title: "Gold",
    durationDays: 30,
    priceJeton: 500,
    bonusJeton: 500,
    falDiscountPercent: 30,
    tierOrder: 3,
  },
  {
    id: "diamond",
    title: "Diamond",
    durationDays: 30,
    priceJeton: 1000,
    bonusJeton: 1000,
    falDiscountPercent: 40,
    tierOrder: 4,
  },
] as const;

function membershipDaysLeft(expiresAt: Date | null): number | null {
  if (!expiresAt) return null;
  const ms = expiresAt.getTime() - Date.now();
  if (ms <= 0) return 0;
  return Math.ceil(ms / (24 * 60 * 60 * 1000));
}

/** GET /api/membership/packages */
walletRouter.get("/membership/packages", requireAuth, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) return jsonError(res, 404, "Kullanıcı bulunamadı");

  const daysLeft = membershipDaysLeft(user.membershipExpiresAt);
  const activeTier =
    daysLeft != null && daysLeft > 0 ? user.membership : "basic";

  return res.status(200).json({
    packages: MEMBERSHIP_PACKAGES.map((p) => ({
      ...p,
      isActive: p.id === activeTier,
      daysRemaining: p.id === activeTier ? daysLeft : null,
    })),
    currentMembership: activeTier,
    daysRemaining: daysLeft,
    jetonBalance: user.coins,
    cfcBalance: user.cfcBalance,
    features: [
      { id: "bonus", title: "Bonus Jeton", subtitle: "Her paketle bonus jeton" },
      { id: "badge", title: "Özel Rozet", subtitle: "Üyelik rozeti profilde" },
      { id: "support", title: "Öncelikli Destek", subtitle: "7/24 öncelikli destek" },
      { id: "fal", title: "İndirimli Fal", subtitle: "Fal bakımlarında indirim" },
    ],
  });
});

/** POST /api/membership/purchase */
walletRouter.post("/membership/purchase", requireAuth, async (req, res) => {
  const tierId = String(req.body?.tierId ?? req.body?.packageId ?? "").toLowerCase();
  const pkg = MEMBERSHIP_PACKAGES.find((p) => p.id === tierId);
  if (!pkg) return jsonError(res, 400, "Geçersiz paket");

  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) return jsonError(res, 404, "Kullanıcı bulunamadı");

  if (user.coins < pkg.priceJeton) {
    return jsonError(res, 400, "Yetersiz jeton bakiyesi");
  }

  const now = new Date();
  const base =
    user.membership === pkg.id &&
    user.membershipExpiresAt &&
    user.membershipExpiresAt > now
      ? user.membershipExpiresAt
      : now;
  const expires = new Date(base);
  expires.setDate(expires.getDate() + pkg.durationDays);

  const newCoins = user.coins - pkg.priceJeton + pkg.bonusJeton;
  const updated = await prisma.user.update({
    where: { id: user.id },
    data: {
      coins: newCoins,
      membership: pkg.id,
      membershipExpiresAt: expires,
    },
  });

  const isExtend =
    user.membership === pkg.id &&
    user.membershipExpiresAt != null &&
    user.membershipExpiresAt > now;

  await createNotification({
    userId: user.id,
    title: isExtend ? "Üyelik uzatıldı" : "Premium üyelik aktif",
    body: `${pkg.title} · ${pkg.durationDays} gün`,
    type: "membership",
    targetPath: "/premium-membership",
    targetId: pkg.id,
  });

  return res.status(200).json({
    success: true,
    membership: updated.membership,
    membershipExpiresAt: updated.membershipExpiresAt?.toISOString() ?? null,
    daysRemaining: membershipDaysLeft(updated.membershipExpiresAt),
    jetonBalance: updated.coins,
    cfcBalance: updated.cfcBalance,
    bonusJetonGranted: pkg.bonusJeton,
  });
});

export { isStaffRole };
