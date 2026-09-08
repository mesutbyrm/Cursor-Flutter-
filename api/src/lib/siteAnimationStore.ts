import fs from "node:fs/promises";
import path from "node:path";

export type SiteAnimationRecord = {
  id: string;
  name: string;
  category: string;
  membership: string;
  animationType: string;
  assetUrl?: string | null;
  previewUrl?: string | null;
  soundUrl?: string | null;
  durationMs: number;
  priority: number;
  rarity: string;
  context: string;
  anchor: string;
  scale: number;
  cooldownMs: number;
  isActive: boolean;
  description?: string | null;
  previewMp4Key?: string | null;
};

type StoreFile = {
  animations: SiteAnimationRecord[];
  defaults: Record<string, string>;
  assignments: Record<string, Record<string, string | null>>;
};

const STORE_PATH = path.join(process.cwd(), "data", "site_animations.json");

const SEED: SiteAnimationRecord[] = [
  {
    id: "anim_entrance_normal",
    name: "Normal Giriş — Hoş geldin",
    category: "entrance",
    membership: "normal",
    animationType: "native",
    durationMs: 2500,
    priority: 50,
    rarity: "common",
    context: "voice_room",
    anchor: "TOP_LEFT",
    scale: 1,
    cooldownMs: 0,
    isActive: true,
    description: "Mavi halka, sade banner — 2.5 sn",
  },
  {
    id: "anim_entrance_gold_crown",
    name: "Golden Crown — Gold Üye Girişi",
    category: "entrance",
    membership: "gold",
    animationType: "native",
    durationMs: 3000,
    priority: 70,
    rarity: "common",
    context: "voice_room",
    anchor: "TOP_LEFT",
    scale: 1,
    cooldownMs: 0,
    isActive: true,
    description: "Altın taç + glow + VIP rozeti",
    previewMp4Key: "gold_uye_girisi.mp4",
  },
  {
    id: "anim_entrance_diamond_burst",
    name: "Diamond Burst — Diamond Üye Girişi",
    category: "entrance",
    membership: "diamond",
    animationType: "native",
    durationMs: 4000,
    priority: 90,
    rarity: "epic",
    context: "voice_room",
    anchor: "TOP_LEFT",
    scale: 1,
    cooldownMs: 0,
    isActive: true,
    description: "Mavi kristal patlaması",
    previewMp4Key: "diamond_uye_girisi.mp4",
  },
];

const DEFAULT_DEFAULTS: Record<string, string> = {
  normal: "anim_entrance_normal",
  gold: "anim_entrance_gold_crown",
  premium: "anim_entrance_premium_star",
  diamond: "anim_entrance_diamond_burst",
  vip: "anim_entrance_vip_galaxy",
  svip: "anim_entrance_svip_emperor",
  admin: "anim_entrance_admin_galaxy",
  host: "anim_host_seat_crown",
};

let memory: StoreFile | null = null;

async function readStore(): Promise<StoreFile> {
  if (memory) return memory;
  try {
    const raw = await fs.readFile(STORE_PATH, "utf8");
    memory = JSON.parse(raw) as StoreFile;
    return memory;
  } catch {
    memory = {
      animations: [...SEED],
      defaults: { ...DEFAULT_DEFAULTS },
      assignments: {},
    };
    await writeStore(memory);
    return memory;
  }
}

async function writeStore(next: StoreFile): Promise<void> {
  memory = next;
  await fs.mkdir(path.dirname(STORE_PATH), { recursive: true });
  await fs.writeFile(STORE_PATH, JSON.stringify(next, null, 2), "utf8");
}

export async function listSiteAnimations(): Promise<SiteAnimationRecord[]> {
  const store = await readStore();
  return store.animations;
}

export async function listActiveSiteAnimations(): Promise<SiteAnimationRecord[]> {
  const store = await readStore();
  return store.animations.filter((a) => a.isActive);
}

export async function getSiteAnimationStats() {
  const items = await listSiteAnimations();
  const active = items.filter((a) => a.isActive).length;
  return {
    total: items.length,
    active,
    inactive: items.length - active,
    entrance: items.filter((a) => a.category === "entrance").length,
    exit: items.filter((a) => a.category === "exit").length,
    seat: items.filter((a) => a.category === "seat").length,
    vip: items.filter((a) => a.membership === "vip" || a.membership === "svip")
      .length,
    profileFrame: items.filter((a) => a.category === "profileFrame").length,
    gift: items.filter((a) => a.category === "gift").length,
  };
}

export async function createSiteAnimation(
  body: Partial<SiteAnimationRecord>,
): Promise<SiteAnimationRecord> {
  const store = await readStore();
  const id = body.id?.trim() || `anim_${Date.now()}`;
  const item: SiteAnimationRecord = {
    id,
    name: body.name?.trim() || "Animasyon",
    category: body.category || "entrance",
    membership: body.membership || "normal",
    animationType: body.animationType || "native",
    assetUrl: body.assetUrl ?? null,
    previewUrl: body.previewUrl ?? null,
    soundUrl: body.soundUrl ?? null,
    durationMs: Number(body.durationMs) || 3000,
    priority: Number(body.priority) || 50,
    rarity: body.rarity || "common",
    context: body.context || "voice_room",
    anchor: body.anchor || "TOP_LEFT",
    scale: Number(body.scale) || 1,
    cooldownMs: Number(body.cooldownMs) || 0,
    isActive: body.isActive !== false,
    description: body.description ?? null,
    previewMp4Key: body.previewMp4Key ?? null,
  };
  store.animations.push(item);
  await writeStore(store);
  return item;
}

export async function updateSiteAnimation(
  id: string,
  patch: Partial<SiteAnimationRecord>,
): Promise<SiteAnimationRecord | null> {
  const store = await readStore();
  const idx = store.animations.findIndex((a) => a.id === id);
  if (idx < 0) return null;
  store.animations[idx] = { ...store.animations[idx], ...patch, id };
  await writeStore(store);
  return store.animations[idx];
}

export async function getSiteAnimationDefaults(): Promise<Record<string, string>> {
  const store = await readStore();
  return store.defaults;
}

export async function saveSiteAnimationDefaults(
  defaults: Record<string, string>,
): Promise<Record<string, string>> {
  const store = await readStore();
  store.defaults = { ...store.defaults, ...defaults };
  await writeStore(store);
  return store.defaults;
}

export async function getUserSiteAnimationAssignments(userId: string) {
  const store = await readStore();
  return store.assignments[userId] ?? {};
}

export async function assignSiteAnimation(input: {
  userId: string;
  slot: string;
  animationId?: string | null;
  expiresAt?: string | null;
}) {
  const store = await readStore();
  const user = { ...(store.assignments[input.userId] ?? {}) };
  user[input.slot] = input.animationId ?? null;
  if (input.expiresAt) user[`${input.slot}_expiresAt`] = input.expiresAt;
  store.assignments[input.userId] = user;
  await writeStore(store);
  return user;
}

export async function bulkAssignSiteAnimation(input: {
  userIds: string[];
  slot: string;
  animationId: string;
  expiresAt?: string | null;
}) {
  for (const userId of input.userIds) {
    await assignSiteAnimation({
      userId,
      slot: input.slot,
      animationId: input.animationId,
      expiresAt: input.expiresAt,
    });
  }
}

export async function activeCatalogPayload() {
  const store = await readStore();
  return {
    animations: store.animations.filter((a) => a.isActive),
    defaults: store.defaults,
  };
}
