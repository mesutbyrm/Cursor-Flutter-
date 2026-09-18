import type { Prisma } from "@prisma/client";
import { prisma } from "./prisma";

export type GiftChargeResult<T> =
  | { ok: true; event: T; newBalance?: number }
  | { ok: false; reason: "USER_NOT_FOUND" | "INSUFFICIENT_COINS" };

/** Transaction yürütücüsü — testte sahte istemci geçirebilmek için dar tutuldu. */
export type GiftChargeDb = {
  $transaction<R>(fn: (tx: Prisma.TransactionClient) => Promise<R>): Promise<R>;
};

/**
 * Jeton düşümü ile hediye kaydını tek transaction içinde yürütür.
 *
 * Bakiye kontrolü ile düşme ayrı sorgular olduğunda araya giren eşzamanlı bir
 * istek aynı bakiyeyi okuyabiliyor, ikisi de kontrolü geçiyor ve bakiye
 * negatife inebiliyordu. Koşul artık `updateMany` filtresinde: düşme yalnızca
 * bakiye yeterliyse gerçekleşir, `count === 0` yetersizliği bildirir.
 *
 * Kayıt aynı transaction içinde oluşturulur; `createEvent` hata verirse jeton
 * düşümü geri alınır (önceden jeton düşüp kayıt oluşmayabiliyordu).
 *
 * Yayın/kuyruk/bildirim gibi yan etkiler ÇAĞIRANDA, commit sonrasında
 * kalmalıdır — transaction içine alınırlarsa rollback edilen bir hediye için
 * olay yayılır.
 */
export async function chargeAndRecordGift<T>(params: {
  userId?: string | null;
  totalCost: number;
  createEvent: (tx: Prisma.TransactionClient) => Promise<T>;
  /** Yalnızca test içindir; üretimde varsayılan Prisma istemcisi kullanılır. */
  db?: GiftChargeDb;
}): Promise<GiftChargeResult<T>> {
  const { userId, totalCost, createEvent, db } = params;
  // PrismaClient.$transaction aşırı yüklü olduğu için dar `GiftChargeDb` tipiyle
  // doğrudan birleşemiyor; callback formu çalışma zamanında birebir uyuyor.
  const client: GiftChargeDb = db ?? (prisma as unknown as GiftChargeDb);

  return client.$transaction(async (tx) => {
    if (!userId) {
      return { ok: true as const, event: await createEvent(tx) };
    }

    const charged = await tx.user.updateMany({
      where: { id: userId, coins: { gte: totalCost } },
      data: { coins: { decrement: totalCost } },
    });

    if (charged.count === 0) {
      // Hiçbir yazma olmadı; yetersiz bakiye ile olmayan kullanıcıyı ayır.
      const exists = await tx.user.findUnique({
        where: { id: userId },
        select: { id: true },
      });
      return exists
        ? { ok: false as const, reason: "INSUFFICIENT_COINS" as const }
        : { ok: false as const, reason: "USER_NOT_FOUND" as const };
    }

    const after = await tx.user.findUnique({
      where: { id: userId },
      select: { coins: true },
    });

    return {
      ok: true as const,
      event: await createEvent(tx),
      newBalance: after?.coins,
    };
  });
}
