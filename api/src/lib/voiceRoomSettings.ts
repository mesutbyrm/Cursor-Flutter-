import type { RoomType, VoiceRoomSettings } from "@prisma/client";
import { prisma } from "./prisma";

export type VoiceRoomSettingsDto = VoiceRoomSettings;

const DEFAULTS = {
  giftReceiverPercent: 70,
  roomOwnerPercent: 30,
  siteCommissionPercent: 50,
  musicOwnerPercent: 50,
  musicSitePercent: 50,
  vipMusicOwnerPercent: 70,
  vipMusicSitePercent: 30,
  musicRequestCost: 10,
  freeRoomMaxUsers: 15,
  normalRoomMaxUsers: 100,
  vipRoomMaxUsers: 500,
} as const;

export async function getVoiceRoomSettings(): Promise<VoiceRoomSettingsDto> {
  const row = await prisma.voiceRoomSettings.findUnique({ where: { id: "default" } });
  if (row) return row;
  return prisma.voiceRoomSettings.create({
    data: { id: "default", ...DEFAULTS },
  });
}

export type VoiceRoomSettingsPatch = Partial<{
  giftReceiverPercent: number;
  roomOwnerPercent: number;
  siteCommissionPercent: number;
  musicOwnerPercent: number;
  musicSitePercent: number;
  vipMusicOwnerPercent: number;
  vipMusicSitePercent: number;
  musicRequestCost: number;
  freeRoomMaxUsers: number;
  normalRoomMaxUsers: number;
  vipRoomMaxUsers: number;
}>;

function clampPercent(n: number) {
  return Math.min(100, Math.max(0, Math.round(n)));
}

export async function updateVoiceRoomSettings(
  patch: VoiceRoomSettingsPatch,
): Promise<VoiceRoomSettingsDto> {
  await getVoiceRoomSettings();
  const data: VoiceRoomSettingsPatch = {};
  if (patch.giftReceiverPercent != null) {
    data.giftReceiverPercent = clampPercent(patch.giftReceiverPercent);
  }
  if (patch.roomOwnerPercent != null) {
    data.roomOwnerPercent = clampPercent(patch.roomOwnerPercent);
  }
  if (patch.siteCommissionPercent != null) {
    data.siteCommissionPercent = clampPercent(patch.siteCommissionPercent);
  }
  if (patch.musicOwnerPercent != null) {
    data.musicOwnerPercent = clampPercent(patch.musicOwnerPercent);
  }
  if (patch.musicSitePercent != null) {
    data.musicSitePercent = clampPercent(patch.musicSitePercent);
  }
  if (patch.vipMusicOwnerPercent != null) {
    data.vipMusicOwnerPercent = clampPercent(patch.vipMusicOwnerPercent);
  }
  if (patch.vipMusicSitePercent != null) {
    data.vipMusicSitePercent = clampPercent(patch.vipMusicSitePercent);
  }
  if (patch.musicRequestCost != null) {
    data.musicRequestCost = Math.min(500, Math.max(1, Math.round(patch.musicRequestCost)));
  }
  if (patch.freeRoomMaxUsers != null) {
    data.freeRoomMaxUsers = Math.min(50, Math.max(2, Math.round(patch.freeRoomMaxUsers)));
  }
  if (patch.normalRoomMaxUsers != null) {
    data.normalRoomMaxUsers = Math.min(500, Math.max(2, Math.round(patch.normalRoomMaxUsers)));
  }
  if (patch.vipRoomMaxUsers != null) {
    data.vipRoomMaxUsers = Math.min(2000, Math.max(2, Math.round(patch.vipRoomMaxUsers)));
  }
  return prisma.voiceRoomSettings.update({
    where: { id: "default" },
    data,
  });
}

export function maxUsersForRoomType(
  roomType: RoomType,
  settings: Pick<
    VoiceRoomSettingsDto,
    "freeRoomMaxUsers" | "normalRoomMaxUsers" | "vipRoomMaxUsers"
  >,
): number {
  switch (roomType) {
    case "FREE":
      return settings.freeRoomMaxUsers;
    case "VIP":
      return settings.vipRoomMaxUsers;
    default:
      return settings.normalRoomMaxUsers;
  }
}

export function settingsPayload(s: VoiceRoomSettingsDto) {
  return {
    giftReceiverPercent: s.giftReceiverPercent,
    roomOwnerPercent: s.roomOwnerPercent,
    siteCommissionPercent: s.siteCommissionPercent,
    musicOwnerPercent: s.musicOwnerPercent,
    musicSitePercent: s.musicSitePercent,
    vipMusicOwnerPercent: s.vipMusicOwnerPercent,
    vipMusicSitePercent: s.vipMusicSitePercent,
    musicRequestCost: s.musicRequestCost,
    freeRoomMaxUsers: s.freeRoomMaxUsers,
    normalRoomMaxUsers: s.normalRoomMaxUsers,
    vipRoomMaxUsers: s.vipRoomMaxUsers,
    updatedAt: s.updatedAt.toISOString(),
  };
}

export function parseRoomType(raw: unknown): RoomType {
  const v = String(raw ?? "NORMAL").toUpperCase();
  if (v === "FREE" || v === "ÜCRETSİZ" || v === "UCRETSIZ") return "FREE";
  if (v === "VIP") return "VIP";
  return "NORMAL";
}
