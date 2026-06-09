/**
 * canlifal.com sesli oda arka plan kataloğu — web statik dosyalarla aynı.
 * api/src/lib/chatRoomStore.ts listSiteBackgrounds ile senkron tutun.
 */

const ORIGIN = process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ?? "https://canlifal.com";

export const VOICE_BG_COUNT = 20;

export function listVoiceRoomBackgrounds(): string[] {
  return Array.from(
    { length: VOICE_BG_COUNT },
    (_, i) => `${ORIGIN}/images/voice-bg-${i + 1}.jpg`,
  );
}

export type VoiceBackgroundItem = {
  id: string;
  url: string;
  label: string;
};

export function listVoiceRoomBackgroundItems(): VoiceBackgroundItem[] {
  return listVoiceRoomBackgrounds().map((url, i) => ({
    id: `voice-bg-${i + 1}`,
    url,
    label: `Arka plan ${i + 1}`,
  }));
}
