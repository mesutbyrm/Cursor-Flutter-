-- Hediye gönderiminde tekrar-koruma (idempotency).
--
-- Ağ zaman aşımında yapılan retry ya da çift dokunuş aynı anahtarla gelir;
-- unique index ikinci kaydı engeller ve kullanıcıdan ikinci kez ücret alınmaz.
--
-- Kolon nullable: mevcut kayıtlar ve anahtar göndermeyen istemciler etkilenmez.
-- Postgres'te NULL'lar unique index'te birbiriyle çakışmadığı için anahtarsız
-- satırlar sınırsız sayıda var olabilir.

ALTER TABLE "GiftEvent" ADD COLUMN IF NOT EXISTS "idempotencyKey" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "GiftEvent_senderId_idempotencyKey_key"
  ON "GiftEvent"("senderId", "idempotencyKey");
