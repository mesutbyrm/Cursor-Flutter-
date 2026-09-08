import type { SiteAnimationRecord } from "./siteAnimationStore";
import {
  getSiteAnimationDefaults,
  getSiteAnimationExitDefaults,
  getUserSiteAnimationAssignments,
  listActiveSiteAnimations,
} from "./siteAnimationStore";
import {
  SITE_ANIMATION_DEFAULTS,
} from "./siteAnimationSeed";

type ResolveInput = {
  event: string;
  userId: string;
  name?: string;
  membership?: string | null;
  chatRole?: string | null;
  seatIndex?: number | null;
  micOn?: boolean | null;
  previousSeatIndex?: number | null;
};

const ENTRANCE_EVENTS = new Set(["user_joined", "room_member_joined", "join"]);
const EXIT_EVENTS = new Set(["user_left", "room_member_left", "leave"]);
const SEAT_EVENTS = new Set(["seat_changed", "room_member_seat_changed"]);
const MIC_EVENTS = new Set(["mic_changed", "mic_enabled", "mic_disabled", "mic_on", "mic_off"]);
const HOST_EVENTS = new Set(["owner_changed", "host_changed"]);

function normalizeMembership(raw?: string | null, chatRole?: string | null) {
  const role = chatRole?.toLowerCase().trim();
  if (role === "admin" || role === "founder") return "admin";
  if (role === "owner" || role === "host") return "host";
  const m = raw?.toLowerCase().trim() ?? "normal";
  if (m === "basic") return "normal";
  return m;
}

function categoryForEvent(event: string, micOn?: boolean | null) {
  const e = event.toLowerCase();
  if (ENTRANCE_EVENTS.has(e)) return "entrance";
  if (EXIT_EVENTS.has(e)) return "exit";
  if (SEAT_EVENTS.has(e)) return "transition";
  if (HOST_EVENTS.has(e)) return "host";
  if (MIC_EVENTS.has(e)) return "mic";
  if (e === "mic_changed") return micOn ? "mic" : "mic";
  return null;
}

function slotForEvent(event: string, micOn?: boolean | null) {
  const e = event.toLowerCase();
  if (ENTRANCE_EVENTS.has(e) || HOST_EVENTS.has(e)) return "entrance";
  if (EXIT_EVENTS.has(e)) return "exit";
  if (SEAT_EVENTS.has(e)) return "seat";
  if (MIC_EVENTS.has(e) || e === "mic_changed") return "mic";
  return null;
}

function pickByCategory(
  animations: SiteAnimationRecord[],
  category: string,
  membership: string,
) {
  const active = animations.filter((a) => a.isActive && a.category === category);
  return (
    active.find((a) => a.membership === membership) ??
    active.find((a) => a.membership === "all") ??
    active[0] ??
    null
  );
}

async function pickAnimation(input: ResolveInput): Promise<SiteAnimationRecord | null> {
  const event = input.event.toLowerCase();
  const membership = normalizeMembership(input.membership, input.chatRole);
  const animations = await listActiveSiteAnimations();
  const byId = new Map(animations.map((a) => [a.id, a]));

  const slot = slotForEvent(event, input.micOn);
  if (slot && input.userId) {
    const assignments = await getUserSiteAnimationAssignments(input.userId);
    const assignedId = assignments[slot];
    if (assignedId && byId.has(assignedId)) {
      return byId.get(assignedId)!;
    }
  }

  if (ENTRANCE_EVENTS.has(event)) {
    const defaults = await getSiteAnimationDefaults();
    const id = defaults[membership] ?? SITE_ANIMATION_DEFAULTS[membership];
    if (id) {
      const fromDefault = byId.get(id);
      if (fromDefault) return fromDefault;
      return null;
    }
  }

  if (EXIT_EVENTS.has(event)) {
    const exitDefaults = await getSiteAnimationExitDefaults();
    const id = exitDefaults[membership];
    if (id) {
      const fromDefault = byId.get(id);
      if (fromDefault) return fromDefault;
      return null;
    }
  }

  const category = categoryForEvent(event, input.micOn);
  if (!category) return null;

  if (category === "mic") {
    const micId =
      input.micOn === false || event.includes("off") || event.includes("disabled")
        ? "anim_mic_off"
        : "anim_mic_on";
    if (byId.has(micId)) return byId.get(micId)!;
  }

  return pickByCategory(animations, category, membership);
}

export async function buildSiteAnimationRoomEvent(
  input: ResolveInput,
): Promise<Record<string, unknown> | null> {
  const anim = await pickAnimation(input);
  if (!anim || !anim.isActive) return null;

  const event = input.event.toLowerCase();
  const payload: Record<string, unknown> = {
    type: "room_event",
    event,
    roomId: undefined,
    userId: input.userId,
    name: input.name ?? "Kullanıcı",
    membership: normalizeMembership(input.membership, input.chatRole),
    chatRole: input.chatRole ?? undefined,
    seatIndex: input.seatIndex ?? undefined,
    micOn: input.micOn ?? undefined,
    previousSeatIndex: input.previousSeatIndex ?? undefined,
    eventId: `${input.userId}:${event}:${Date.now()}`,
    animation: {
      id: anim.id,
      assetUrl: anim.assetUrl,
      assetType: anim.animationType,
      anchor: anim.anchor,
      scale: anim.scale,
      durationMs: anim.durationMs,
      priority: anim.priority,
      previewMp4Key: anim.previewMp4Key,
    },
  };

  return payload;
}
