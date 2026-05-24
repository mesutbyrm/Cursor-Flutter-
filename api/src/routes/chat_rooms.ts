import { Router } from "express";
import { optionalAuth } from "../middleware/optionalAuth";
import { requireAuth } from "../middleware/requireAuth";
import { listRoomGiftEvents, sendRoomGift } from "./gifts";

export const chatRoomsRouter = Router();

chatRoomsRouter.get("/rooms/:roomId/gifts", async (req, res) => {
  const since = req.query.since as string | undefined;
  return listRoomGiftEvents(req.params.roomId, since, res);
});

chatRoomsRouter.post(
  "/rooms/:roomId/gifts",
  optionalAuth,
  async (req, res) => {
    return sendRoomGift(req.params.roomId, req.body, req.userId, res);
  },
);
