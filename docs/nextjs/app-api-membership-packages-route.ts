/**
 * canlifal.com Next.js — premium üyelik paketleri
 *
 * Hedef: app/api/membership/packages/route.ts
 *
 * Kaynak: api/src/routes/wallet.ts MEMBERSHIP_PACKAGES
 */

import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireApiAuth } from "@/lib/verifyApiAuth";

const MEMBERSHIP_PACKAGES = [
  { id: "basic", title: "Basic", durationDays: 30, priceJeton: 100, bonusJeton: 100, falDiscountPercent: 10, tierOrder: 1 },
  { id: "premium", title: "Premium", durationDays: 30, priceJeton: 250, bonusJeton: 250, falDiscountPercent: 20, tierOrder: 2 },
  { id: "gold", title: "Gold", durationDays: 30, priceJeton: 500, bonusJeton: 500, falDiscountPercent: 30, tierOrder: 3 },
  { id: "diamond", title: "Diamond", durationDays: 30, priceJeton: 1000, bonusJeton: 1000, falDiscountPercent: 40, tierOrder: 4 },
] as const;

function membershipDaysLeft(expiresAt: Date | null | undefined): number | null {
  if (!expiresAt) return null;
  const ms = expiresAt.getTime() - Date.now();
  if (ms <= 0) return 0;
  return Math.ceil(ms / (24 * 60 * 60 * 1000));
}

export async function GET(request: NextRequest) {
  const auth = await requireApiAuth(request);
  if (!auth) {
    return NextResponse.json(
      { error: "Oturum açmanız gerekiyor" },
      { status: 401 },
    );
  }

  const user = await prisma.user.findUnique({ where: { id: auth.userId } });
  if (!user) {
    return NextResponse.json({ error: "Kullanıcı bulunamadı" }, { status: 404 });
  }

  const daysLeft = membershipDaysLeft(user.membershipExpiresAt);
  const activeTier =
    daysLeft != null && daysLeft > 0 ? user.membership : "basic";

  return NextResponse.json({
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
}
