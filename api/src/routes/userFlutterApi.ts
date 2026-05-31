import { Router } from "express";
import { requireAuth } from "../middleware/requireAuth";
import {
  getActivity,
  getBroadcastHistory,
  patchActivityMarkAllRead,
} from "../lib/userProfileApiHandlers";

/** canlifal.com Flutter API — /api/user/* (doküman: canlifal-flutter-api-docs.txt) */
export const userFlutterApiRouter = Router();

userFlutterApiRouter.get("/broadcast-history", requireAuth, getBroadcastHistory);
userFlutterApiRouter.get("/activity", requireAuth, getActivity);
userFlutterApiRouter.patch("/activity", requireAuth, patchActivityMarkAllRead);
