import { buildSiteAnimationRoomEvent } from "./siteAnimationResolver";
import { emitRoomEventSse } from "./roomEventSse";

export async function emitResolvedRoomAnimation(
  roomId: string,
  input: Parameters<typeof buildSiteAnimationRoomEvent>[0],
) {
  const payload = await buildSiteAnimationRoomEvent(input);
  if (payload) emitRoomEventSse(roomId, payload);
}
