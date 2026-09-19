import type { Prisma } from "@prisma/client";
import { prisma } from "./prisma";

export type GiftChargeResult<T> =
  | { ok: true; event: T; newBalance?: number; replayed?: boolean }
  | { ok: false; reason: "USER_NOT_FOUND" | "INSUFFICIENT_COINS" };

/** Transaction yürütücüsü — testte sahte istemci geçirebilmek için dar tutuldu. */
export type GiftChargeDb = {
  $transaction<R>(fn: (tx: Prisma.TransactionClient) => Promise<R>): Promise<R>;
};

/** Alıcı aramasında kullanılan dar arayüz — testte sahte istemci için. */
export type GiftReceiverDb = {
  user: {
    findMany(args: {
      where: { OR: Array<{ username?: string; displayName?: string }> };
      select: { id: true; username: true };
      take: number;
    }): Promise<Array<{ id: string; username: string | null }>>;
  };
};

/**
 * Hediye alıcısını çözer.
 *
 * Önceden `findFirst({ OR: [{ username }, { displayName }] })` kullanılıyordu.
 * `username` benzersizdir ama **`displayName` değildir**; aynı görünen adı
 * taşıyan birden fazla hesap varsa `findFirst` rastgele birini seçiyor ve
 * hediye ile gelir **yanlış kullanıcıya** yazılabiliyordu.
 *
 * Artık: benzersiz `username` eşleşmesi tercih edilir; `displayName` yalnızca
 * **tek** eşleşme varsa kabul edilir. Belirsizlikte alıcı boş bırakılır —
 * hediye yine kaydedilir, ama gelir yanlış hesaba yazılmaz.
 */
export async function resolveGiftReceiverId(params: {
  receiverId?: string | null;
  receiverName?: string | null;
  db?: GiftReceiverDb;
}): Promise<string | null> {
  const explicit = params.receiverId?.trim();
  if (explicit) return explicit;

  const name = params.receiverName?.trim();
  if (!name || name === "Yayıncı") return null;

  const client = params.db ?? (prisma as unknown as GiftReceiverDb);
  const username = name.replace(/^@/, "");

  // take: 2 — tek eşleşme mi yoksa belirsizlik mi olduğunu ayırt etmeye yeter.
  const rows = await client.user.findMany({
    where: { OR: [{ username }, { displayName: name }] },
    select: { id: true, username: true },
    take: 2,
  });

  const byUsername = rows.find((r) => r.username === username);
  if (byUsername) return byUsername.id;

  return rows.length === 1 ? rows[0].id : null;
}

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
  /**
   * Tekrar-koruma anahtarı. Verildiğinde aynı anahtarla gelen ikinci istek
   * yeniden ücretlendirilmez; ilk kayıt döndürülür (`replayed: true`).
   *
   * **Dağıtım notu:** `idempotencyKey` kolonuna yalnızca bu alan doluyken
   * dokunulur. Anahtar göndermeyen istemciler için hiçbir sorgu kolonu
   * referans almaz, bu yüzden bu kod migration'dan önce dağıtılsa da
   * kırılmaz.
   */
  idempotencyKey?: string | null;
  /** Yalnızca `idempotencyKey` verildiğinde çağrılır. */
  findExisting?: (tx: Prisma.TransactionClient) => Promise<T | null>;
  /** Yalnızca test içindir; üretimde varsayılan Prisma istemcisi kullanılır. */
  db?: GiftChargeDb;
}): Promise<GiftChargeResult<T>> {
  const { userId, totalCost, createEvent, idempotencyKey, findExisting, db } =
    params;
  // PrismaClient.$transaction aşırı yüklü olduğu için dar `GiftChargeDb` tipiyle
  // doğrudan birleşemiyor; callback formu çalışma zamanında birebir uyuyor.
  const client: GiftChargeDb = db ?? (prisma as unknown as GiftChargeDb);

  return client.$transaction(async (tx) => {
    if (!userId) {
      return { ok: true as const, event: await createEvent(tx) };
    }

    // Tekrar gelen istek: jeton düşmeden ilk kaydı döndür.
    if (idempotencyKey && findExisting) {
      const prior = await findExisting(tx);
      if (prior) {
        const current = await tx.user.findUnique({
          where: { id: userId },
          select: { coins: true },
        });
        return {
          ok: true as const,
          event: prior,
          newBalance: current?.coins,
          replayed: true,
        };
      }
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
