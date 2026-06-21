/** Ödeme bildirimi — sabit admin e-postası + isteğe bağlı Resend API. */
export const PAYMENT_ALERT_EMAIL = "mesutbyrm1@gmail.com";

export async function sendPaymentAdminEmail(input: {
  paymentRequestId: string;
  requestType: "jeton" | "cfc";
  username?: string;
  packageName?: string;
  amountLabel: string;
  amountTry?: number;
  method: string;
  senderInfo?: string | null;
  notes?: string | null;
}): Promise<void> {
  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey) {
    console.warn(
      "[payment-email] RESEND_API_KEY tanımlı değil — e-posta atlanıyor",
    );
    return;
  }

  const amountText =
    input.amountTry != null && Number.isFinite(input.amountTry)
      ? `${input.amountTry} TL`
      : input.amountLabel;
  const subject = `Canlifal — yeni ${input.requestType} ödeme bildirimi`;
  const text = [
    `Talep ID: ${input.paymentRequestId}`,
    `Tür: ${input.requestType}`,
    `Kullanıcı: ${input.username ?? "—"}`,
    `Paket: ${input.packageName ?? input.amountLabel}`,
    `Tutar: ${amountText}`,
    `Yöntem: ${input.method}`,
    input.senderInfo ? `Gönderen: ${input.senderInfo}` : null,
    input.notes ? `Not: ${input.notes}` : null,
  ]
    .filter(Boolean)
    .join("\n");

  const from =
    process.env.PAYMENT_EMAIL_FROM?.trim() ??
    "Canlifal <noreply@canlifal.com>";

  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [PAYMENT_ALERT_EMAIL],
        subject,
        text,
      }),
    });
    if (!res.ok) {
      const body = await res.text().catch(() => "");
      console.error("[payment-email] Resend failed", res.status, body);
    }
  } catch (err) {
    console.error("[payment-email] send failed", err);
  }
}
