import { Router } from "express";
import { jsonError } from "../lib/jsonError";
import { generateTrtcUserSig } from "../lib/trtcUserSig";
import { optionalAuth } from "../middleware/optionalAuth";

export const trtcRouter = Router();

/** POST /api/trtc/usersig — canlifal.com + Flutter TRTC */
trtcRouter.post("/usersig", optionalAuth, async (req, res) => {
  const userId =
    (req.body?.userId as string | undefined)?.trim() ||
    req.userId ||
    `guest-${Date.now()}`;
  const roomId = (req.body?.roomId as string | undefined)?.trim() ?? "";

  try {
    const cred = generateTrtcUserSig(userId);
    return res.status(200).json({
      sdkAppId: cred.sdkAppId,
      userSig: cred.userSig,
      userId: cred.userId,
      roomId,
      trtcRoomId: roomId,
      role: req.body?.role?.toString() ?? "audience",
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "UserSig generation failed";
    return jsonError(res, 500, msg);
  }
});

/** POST /api/trtc/token — kılavuz §9.13 birincil uç */
trtcRouter.post("/token", optionalAuth, async (req, res) => {
  const userId =
    (req.body?.userId as string | undefined)?.trim() ||
    req.userId ||
    `guest-${Date.now()}`;
  const roomId = (req.body?.roomId as string | undefined)?.trim() ?? "";

  try {
    const cred = generateTrtcUserSig(userId);
    return res.status(200).json({
      success: true,
      data: {
        sdkAppId: cred.sdkAppId,
        userSig: cred.userSig,
        userId: cred.userId,
        roomId,
        trtcRoomId: roomId,
        role: req.body?.role?.toString() ?? "audience",
      },
      sdkAppId: cred.sdkAppId,
      userSig: cred.userSig,
      userId: cred.userId,
      roomId,
      trtcRoomId: roomId,
      role: req.body?.role?.toString() ?? "audience",
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "UserSig generation failed";
    return jsonError(res, 500, msg);
  }
});
