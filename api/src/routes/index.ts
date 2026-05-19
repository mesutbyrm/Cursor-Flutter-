import { Router, Request, Response } from "express";
import authRoutes from "./authRoutes";
import userRoutes from "./userRoutes";
import { sendSuccess } from "../utils/response";

const router = Router();

router.get("/health", (_req: Request, res: Response) => {
  sendSuccess(res, {
    status: "ok",
    timestamp: new Date().toISOString(),
  });
});

router.use("/auth", authRoutes);
router.use("/users", userRoutes);

export default router;
