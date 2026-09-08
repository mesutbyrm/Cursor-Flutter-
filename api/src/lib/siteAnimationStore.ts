import fs from "node:fs/promises";
import path from "node:path";
import type { SiteAnimation } from "@prisma/client";
import { prisma } from "./prisma";
import {
  SITE_ANIMATION_DEFAULTS,
  SITE_ANIMATION_EXIT_DEFAULTS,
  SITE_ANIMATION_SEED,
} from "./siteAnimationSeed";

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
  exitDefaults?: Record<string, string>;
  assignments: Record<string, Record<string, string | null>>;
};

const STORE_PATH = path.join(process.cwd(), "data", "site_animations.json");

let memory: StoreFile | null = null;
let usePrisma: boolean | null = null;

/** Test helper — JSON store sıfırlama. */
export async function resetSiteAnimationStoreForTests() {
  memory = null;
  usePrisma = null;
  try {
    await fs.unlink(STORE_PATH);
  } catch {
    /* yoksa sorun değil */
  }
}

function dbEnabled() {
  return Boolean(process.env.DATABASE_URL);
}

async function canUsePrisma(): Promise<boolean> {
  if (process.env.SITE_ANIMATION_STORE_JSON === "1") return false;
  if (!dbEnabled()) return false;
  if (usePrisma != null) return usePrisma;
  try {
    await prisma.siteAnimation.count();
    usePrisma = true;
  } catch {
    usePrisma = false;
  }
  return usePrisma;
}

function toRecord(row: SiteAnimation): SiteAnimationRecord {
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    membership: row.membership,
    animationType: row.animationType,
    assetUrl: row.assetUrl,
    previewUrl: row.previewUrl,
    soundUrl: row.soundUrl,
    durationMs: row.durationMs,
    priority: row.priority,
    rarity: row.rarity,
    context: row.context,
    anchor: row.anchor,
    scale: row.scale,
    cooldownMs: row.cooldownMs,
    isActive: row.isActive,
    description: row.description,
    previewMp4Key: row.previewMp4Key,
  };
}

async function readJsonStore(): Promise<StoreFile> {
  if (memory) return memory;
  try {
    const raw = await fs.readFile(STORE_PATH, "utf8");
    memory = JSON.parse(raw) as StoreFile;
    return memory;
  } catch {
    memory = {
      animations: [...SITE_ANIMATION_SEED],
      defaults: { ...SITE_ANIMATION_DEFAULTS },
      exitDefaults: { ...SITE_ANIMATION_EXIT_DEFAULTS },
      assignments: {},
    };
    await writeJsonStore(memory);
    return memory;
  }
}

async function writeJsonStore(next: StoreFile): Promise<void> {
  memory = next;
  await fs.mkdir(path.dirname(STORE_PATH), { recursive: true });
  await fs.writeFile(STORE_PATH, JSON.stringify(next, null, 2), "utf8");
}

export async function listSiteAnimations(): Promise<SiteAnimationRecord[]> {
  if (await canUsePrisma()) {
    const rows = await prisma.siteAnimation.findMany({
      orderBy: [{ priority: "desc" }, { name: "asc" }],
    });
    return rows.map(toRecord);
  }
  const store = await readJsonStore();
  return store.animations;
}

export async function listActiveSiteAnimations(): Promise<SiteAnimationRecord[]> {
  if (await canUsePrisma()) {
    const rows = await prisma.siteAnimation.findMany({
      where: { isActive: true },
      orderBy: [{ priority: "desc" }, { name: "asc" }],
    });
    return rows.map(toRecord);
  }
  const store = await readJsonStore();
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

  if (await canUsePrisma()) {
    const row = await prisma.siteAnimation.create({
      data: {
        id: item.id,
        name: item.name,
        category: item.category,
        membership: item.membership,
        animationType: item.animationType,
        assetUrl: item.assetUrl,
        previewUrl: item.previewUrl,
        soundUrl: item.soundUrl,
        durationMs: item.durationMs,
        priority: item.priority,
        rarity: item.rarity,
        context: item.context,
        anchor: item.anchor,
        scale: item.scale,
        cooldownMs: item.cooldownMs,
        isActive: item.isActive,
        description: item.description,
        previewMp4Key: item.previewMp4Key,
      },
    });
    return toRecord(row);
  }

  const store = await readJsonStore();
  store.animations.push(item);
  await writeJsonStore(store);
  return item;
}

export async function updateSiteAnimation(
  id: string,
  patch: Partial<SiteAnimationRecord>,
): Promise<SiteAnimationRecord | null> {
  if (await canUsePrisma()) {
    try {
      const row = await prisma.siteAnimation.update({
        where: { id },
        data: {
          name: patch.name,
          category: patch.category,
          membership: patch.membership,
          animationType: patch.animationType,
          assetUrl: patch.assetUrl,
          previewUrl: patch.previewUrl,
          soundUrl: patch.soundUrl,
          durationMs: patch.durationMs,
          priority: patch.priority,
          rarity: patch.rarity,
          context: patch.context,
          anchor: patch.anchor,
          scale: patch.scale,
          cooldownMs: patch.cooldownMs,
          isActive: patch.isActive,
          description: patch.description,
          previewMp4Key: patch.previewMp4Key,
        },
      });
      return toRecord(row);
    } catch {
      return null;
    }
  }

  const store = await readJsonStore();
  const idx = store.animations.findIndex((a) => a.id === id);
  if (idx < 0) return null;
  store.animations[idx] = { ...store.animations[idx], ...patch, id };
  await writeJsonStore(store);
  return store.animations[idx];
}

export async function getSiteAnimationDefaults(): Promise<Record<string, string>> {
  if (await canUsePrisma()) {
    const rows = await prisma.siteAnimationDefault.findMany({
      where: { NOT: { membership: { startsWith: "exit:" } } },
    });
    const out: Record<string, string> = {};
    for (const row of rows) out[row.membership] = row.animationId;
    return Object.keys(out).length ? out : { ...SITE_ANIMATION_DEFAULTS };
  }
  const store = await readJsonStore();
  return store.defaults;
}

export async function getSiteAnimationExitDefaults(): Promise<
  Record<string, string>
> {
  if (await canUsePrisma()) {
    const rows = await prisma.siteAnimationDefault.findMany({
      where: { membership: { startsWith: "exit:" } },
    });
    const out: Record<string, string> = {};
    for (const row of rows) {
      out[row.membership.slice("exit:".length)] = row.animationId;
    }
    return Object.keys(out).length ? out : { ...SITE_ANIMATION_EXIT_DEFAULTS };
  }
  const store = await readJsonStore();
  return store.exitDefaults ?? { ...SITE_ANIMATION_EXIT_DEFAULTS };
}

export async function saveSiteAnimationDefaults(
  defaults: Record<string, string>,
): Promise<Record<string, string>> {
  if (await canUsePrisma()) {
    for (const [membership, animationId] of Object.entries(defaults)) {
      if (!membership || !animationId) continue;
      await prisma.siteAnimationDefault.upsert({
        where: { membership },
        create: { membership, animationId },
        update: { animationId },
      });
    }
    return getSiteAnimationDefaults();
  }

  const store = await readJsonStore();
  store.defaults = { ...store.defaults, ...defaults };
  await writeJsonStore(store);
  return store.defaults;
}

export async function saveSiteAnimationExitDefaults(
  defaults: Record<string, string>,
): Promise<Record<string, string>> {
  if (await canUsePrisma()) {
    for (const [membership, animationId] of Object.entries(defaults)) {
      if (!membership || !animationId) continue;
      const key = membership.startsWith("exit:")
        ? membership
        : `exit:${membership}`;
      await prisma.siteAnimationDefault.upsert({
        where: { membership: key },
        create: { membership: key, animationId },
        update: { animationId },
      });
    }
    return getSiteAnimationExitDefaults();
  }

  const store = await readJsonStore();
  store.exitDefaults = { ...(store.exitDefaults ?? {}), ...defaults };
  await writeJsonStore(store);
  return store.exitDefaults;
}

export async function getUserSiteAnimationAssignments(userId: string) {
  if (await canUsePrisma()) {
    const rows = await prisma.siteAnimationUserAssignment.findMany({
      where: { userId },
    });
    const out: Record<string, string | null> = {};
    for (const row of rows) {
      out[row.slot] = row.animationId;
      if (row.expiresAt) {
        out[`${row.slot}_expiresAt`] = row.expiresAt.toISOString();
      }
    }
    return out;
  }
  const store = await readJsonStore();
  return store.assignments[userId] ?? {};
}

export async function assignSiteAnimation(input: {
  userId: string;
  slot: string;
  animationId?: string | null;
  expiresAt?: string | null;
}) {
  if (await canUsePrisma()) {
    const expiresAt = input.expiresAt ? new Date(input.expiresAt) : null;
    await prisma.siteAnimationUserAssignment.upsert({
      where: {
        userId_slot: { userId: input.userId, slot: input.slot },
      },
      create: {
        userId: input.userId,
        slot: input.slot,
        animationId: input.animationId ?? null,
        expiresAt,
      },
      update: {
        animationId: input.animationId ?? null,
        expiresAt,
      },
    });
    return getUserSiteAnimationAssignments(input.userId);
  }

  const store = await readJsonStore();
  const user = { ...(store.assignments[input.userId] ?? {}) };
  user[input.slot] = input.animationId ?? null;
  if (input.expiresAt) user[`${input.slot}_expiresAt`] = input.expiresAt;
  store.assignments[input.userId] = user;
  await writeJsonStore(store);
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
  const animations = await listActiveSiteAnimations();
  const defaults = await getSiteAnimationDefaults();
  const exitDefaults = await getSiteAnimationExitDefaults();
  return {
    animations,
    defaults,
    exitDefaults,
  };
}
