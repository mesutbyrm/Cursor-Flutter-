import { Router } from "express";
import { listCoBroadcastInvites } from "../lib/liveStreamExtrasStore";
import { requireAuth } from "../middleware/requireAuth";
import {
  getActivity,
  getBroadcastHistory,
  patchActivityMarkAllRead,
} from "../lib/userProfileApiHandlers";
import {
  createUserFortune,
  getUserFortune,
  listUserFortunes,
} from "../lib/userFortuneHandlers";
import {
  createUserFavorite,
  deleteUserFavorite,
  listUserFavorites,
} from "../lib/userFavoriteHandlers";

/** canlifal.com Flutter API — /api/user/* (doküman: canlifal-flutter-api-docs.txt) */
export const userFlutterApiRouter = Router();

userFlutterApiRouter.get("/broadcast-history", requireAuth, getBroadcastHistory);

userFlutterApiRouter.get("/co-broadcast-invites", requireAuth, (req, res) => {
  const invites = listCoBroadcastInvites(req.userId!);
  return res.status(200).json({ invites, items: invites });
});
userFlutterApiRouter.get("/activity", requireAuth, getActivity);
userFlutterApiRouter.patch("/activity", requireAuth, patchActivityMarkAllRead);

userFlutterApiRouter.get("/fortunes", requireAuth, listUserFortunes);
userFlutterApiRouter.post("/fortunes", requireAuth, createUserFortune);
userFlutterApiRouter.get("/fortunes/:fortuneId", requireAuth, getUserFortune);

userFlutterApiRouter.get("/favorites", requireAuth, listUserFavorites);
userFlutterApiRouter.post("/favorites", requireAuth, createUserFavorite);
userFlutterApiRouter.delete("/favorites/:id", requireAuth, deleteUserFavorite);
