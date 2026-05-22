/**
 * OneSignal REST API — push gönderimi (yalnızca sunucu).
 * Anahtarlar: ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY (.env, repoya yazılmaz).
 */

const ONESIGNAL_API = "https://api.onesignal.com/notifications";

function config(): { appId: string; apiKey: string } | null {
  const appId = process.env.ONESIGNAL_APP_ID?.trim();
  const apiKey = process.env.ONESIGNAL_REST_API_KEY?.trim();
  if (!appId || !apiKey) return null;
  return { appId, apiKey };
}

export function isOneSignalConfigured(): boolean {
  return config() != null;
}

/** Kullanıcıya push (external_id = uygulamadaki user.id / OneSignal.login). */
export async function sendOneSignalToUser(input: {
  userId: string;
  title: string;
  body?: string;
  data?: Record<string, string>;
  /** Ödeme onayı, mesaj vb. — kapalıyken bile hızlı teslim */
  urgent?: boolean;
}): Promise<boolean> {
  const cfg = config();
  if (!cfg || !input.userId.trim()) return false;

  const payload: Record<string, unknown> = {
    app_id: cfg.appId,
    target_channel: "push",
    include_aliases: { external_id: [input.userId.trim()] },
    headings: { en: input.title, tr: input.title },
    contents: {
      en: input.body ?? input.title,
      tr: input.body ?? input.title,
    },
    data: input.data ?? {},
  };
  if (input.urgent) {
    payload.priority = 10;
    payload.android_channel_id = "canlifal_urgent";
    payload.ios_interruption_level = "active";
  }

  try {
    const res = await fetch(ONESIGNAL_API, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${cfg.apiKey}`,
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const text = await res.text();
      console.warn(`OneSignal push failed (${res.status}): ${text.slice(0, 300)}`);
      return false;
    }
    return true;
  } catch (e) {
    console.warn("OneSignal push error:", e);
    return false;
  }
}
