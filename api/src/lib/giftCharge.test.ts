import { describe, it } from "node:test";
import assert from "node:assert/strict";
import type { Prisma } from "@prisma/client";
import {
  chargeAndRecordGift,
  resolveGiftReceiverId,
  type GiftChargeDb,
  type GiftReceiverDb,
} from "./giftCharge.js";

type UserRow = { id: string; coins: number };

/**
 * Koşullu `updateMany` filtresini gerçek veritabanı gibi uygular: düşme
 * yalnızca bakiye yeterliyse gerçekleşir. Yarış senaryosunu bu sayede tek
 * süreçte, veritabanı olmadan sınayabiliyoruz.
 */
function fakeDb(rows: UserRow[]) {
  const calls = { updateMany: 0, createEvent: 0 };
  const tx = {
    user: {
      async updateMany(args: {
        where: { id: string; coins?: { gte: number } };
        data: { coins: { decrement: number } };
      }) {
        calls.updateMany += 1;
        const row = rows.find((r) => r.id === args.where.id);
        const min = args.where.coins?.gte ?? 0;
        if (!row || row.coins < min) return { count: 0 };
        row.coins -= args.data.coins.decrement;
        return { count: 1 };
      },
      async findUnique(args: { where: { id: string } }) {
        return rows.find((r) => r.id === args.where.id) ?? null;
      },
    },
  };
  const db: GiftChargeDb = {
    async $transaction(fn) {
      return fn(tx as unknown as Prisma.TransactionClient);
    },
  };
  return { db, rows, calls, tx };
}

function createEventStub(calls: { createEvent: number }) {
  return async () => {
    calls.createEvent += 1;
    return { id: "evt-1" };
  };
}

describe("chargeAndRecordGift", () => {
  it("yeterli bakiyede jetonu düşer ve kaydı oluşturur", async () => {
    const { db, rows, calls } = fakeDb([{ id: "u1", coins: 100 }]);

    const res = await chargeAndRecordGift({
      userId: "u1",
      totalCost: 40,
      createEvent: createEventStub(calls),
      db,
    });

    assert.equal(res.ok, true);
    if (res.ok) {
      assert.equal(res.newBalance, 60);
      assert.deepEqual(res.event, { id: "evt-1" });
    }
    assert.equal(rows[0].coins, 60);
    assert.equal(calls.createEvent, 1);
  });

  it("yetersiz bakiyede jeton düşmez ve kayıt oluşmaz", async () => {
    const { db, rows, calls } = fakeDb([{ id: "u1", coins: 10 }]);

    const res = await chargeAndRecordGift({
      userId: "u1",
      totalCost: 40,
      createEvent: createEventStub(calls),
      db,
    });

    assert.equal(res.ok, false);
    if (!res.ok) assert.equal(res.reason, "INSUFFICIENT_COINS");
    assert.equal(rows[0].coins, 10, "bakiye değişmemeli");
    assert.equal(calls.createEvent, 0, "kayıt oluşmamalı");
  });

  it("olmayan kullanıcıyı yetersiz bakiyeden ayırır", async () => {
    const { db, calls } = fakeDb([]);

    const res = await chargeAndRecordGift({
      userId: "yok",
      totalCost: 40,
      createEvent: createEventStub(calls),
      db,
    });

    assert.equal(res.ok, false);
    if (!res.ok) assert.equal(res.reason, "USER_NOT_FOUND");
    assert.equal(calls.createEvent, 0);
  });

  // Asıl kusur buydu: bakiye okuma ile düşme ayrı sorgular olduğunda iki
  // eşzamanlı istek aynı bakiyeyi okuyup ikisi de kontrolü geçebiliyordu.
  it("eşzamanlı iki istek bakiyeyi negatife indiremez", async () => {
    const { db, rows, calls } = fakeDb([{ id: "u1", coins: 100 }]);

    const [a, b] = await Promise.all([
      chargeAndRecordGift({
        userId: "u1",
        totalCost: 100,
        createEvent: createEventStub(calls),
        db,
      }),
      chargeAndRecordGift({
        userId: "u1",
        totalCost: 100,
        createEvent: createEventStub(calls),
        db,
      }),
    ]);

    const okCount = [a, b].filter((r) => r.ok).length;
    assert.equal(okCount, 1, "yalnızca biri geçmeli");
    assert.equal(rows[0].coins, 0, "bakiye negatife inmemeli");
    assert.equal(calls.createEvent, 1, "tek kayıt oluşmalı");
  });

  it("kayıt oluşturma hata verirse hata yukarı taşınır (transaction geri alır)", async () => {
    const { db } = fakeDb([{ id: "u1", coins: 100 }]);

    await assert.rejects(
      chargeAndRecordGift({
        userId: "u1",
        totalCost: 40,
        createEvent: async () => {
          throw new Error("kayıt başarısız");
        },
        db,
      }),
      /kayıt başarısız/,
    );
  });

  it("misafir gönderiminde jeton düşmez ama kayıt oluşur", async () => {
    const { db, calls } = fakeDb([{ id: "u1", coins: 100 }]);

    const res = await chargeAndRecordGift({
      userId: null,
      totalCost: 40,
      createEvent: createEventStub(calls),
      db,
    });

    assert.equal(res.ok, true);
    if (res.ok) assert.equal(res.newBalance, undefined);
    assert.equal(calls.updateMany, 0, "misafirde düşme denenmemeli");
    assert.equal(calls.createEvent, 1);
  });
});

type PersonRow = { id: string; username: string | null; displayName: string | null };

function fakeReceiverDb(rows: PersonRow[]): GiftReceiverDb {
  return {
    user: {
      async findMany(args: {
        where: { OR: Array<{ username?: string; displayName?: string }> };
        select: { id: true; username: true };
        take: number;
      }) {
        const hits = rows.filter((r) =>
          args.where.OR.some(
            (w) =>
              (w.username !== undefined && r.username === w.username) ||
              (w.displayName !== undefined && r.displayName === w.displayName),
          ),
        );
        return hits
          .slice(0, args.take)
          .map((r) => ({ id: r.id, username: r.username }));
      },
    },
  };
}

describe("resolveGiftReceiverId", () => {
  it("açık receiverId her şeyin önünde gelir", async () => {
    const db = fakeReceiverDb([{ id: "u9", username: "baska", displayName: null }]);
    const id = await resolveGiftReceiverId({
      receiverId: "  u1  ",
      receiverName: "Mesut",
      db,
    });
    assert.equal(id, "u1");
  });

  it("benzersiz username ile çözer (@ öneki yok sayılır)", async () => {
    const db = fakeReceiverDb([
      { id: "u1", username: "mesut", displayName: "Bir Ad" },
      { id: "u2", username: "baska", displayName: "mesut" },
    ]);
    const id = await resolveGiftReceiverId({ receiverName: "@mesut", db });
    assert.equal(id, "u1", "displayName eşleşmesi değil, username kazanmalı");
  });

  it("tek displayName eşleşmesini kabul eder", async () => {
    const db = fakeReceiverDb([
      { id: "u1", username: "abc", displayName: "Yıldız" },
    ]);
    const id = await resolveGiftReceiverId({ receiverName: "Yıldız", db });
    assert.equal(id, "u1");
  });

  // Asıl kusur: displayName benzersiz değil, findFirst rastgele birini seçip
  // hediyeyi ve geliri yanlış kullanıcıya yazabiliyordu.
  it("aynı displayName'e sahip iki kullanıcıda alıcı seçmez", async () => {
    const db = fakeReceiverDb([
      { id: "u1", username: "a", displayName: "Yıldız" },
      { id: "u2", username: "b", displayName: "Yıldız" },
    ]);
    const id = await resolveGiftReceiverId({ receiverName: "Yıldız", db });
    assert.equal(id, null, "belirsizlikte rastgele kullanıcı seçilmemeli");
  });

  it("eşleşme yoksa null döner", async () => {
    const db = fakeReceiverDb([]);
    const id = await resolveGiftReceiverId({ receiverName: "Kimse", db });
    assert.equal(id, null);
  });

  it("varsayılan 'Yayıncı' adı için arama yapılmaz", async () => {
    const db = fakeReceiverDb([
      { id: "u1", username: "yayinci", displayName: "Yayıncı" },
    ]);
    const id = await resolveGiftReceiverId({ receiverName: "Yayıncı", db });
    assert.equal(id, null);
  });
});
