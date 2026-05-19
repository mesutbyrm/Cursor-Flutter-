import { Request, Response, NextFunction } from "express";
import * as authService from "../services/authService";
import { sendSuccess } from "../utils/response";
import { env } from "../config/env";
import { AuthenticatedRequest } from "../middleware/auth";

export async function register(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, password, name, phone } = req.body;
    const result = await authService.registerUser({ email, password, name, phone });
    sendSuccess(res, result, {
      status: 201,
      message: "Kayıt başarılı.",
    });
  } catch (err) {
    next(err);
  }
}

export async function login(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email, password } = req.body;
    const result = await authService.loginUser(email, password);
    sendSuccess(res, result, { message: "Giriş başarılı." });
  } catch (err) {
    next(err);
  }
}

export async function refresh(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { refreshToken } = req.body;
    const result = await authService.refreshSession(refreshToken);
    sendSuccess(res, result, { message: "Token yenilendi." });
  } catch (err) {
    next(err);
  }
}

export async function logout(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await authService.logoutUser(req.user!.id);
    sendSuccess(res, null, { message: "Çıkış yapıldı." });
  } catch (err) {
    next(err);
  }
}

export async function forgotPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { email } = req.body;
    const { resetToken } = await authService.requestPasswordReset(email);
    const data: Record<string, unknown> = {
      message:
        "E-posta kayıtlıysa sıfırlama talimatları gönderildi.",
    };
    if (env.nodeEnv === "development" && resetToken) {
      data.devResetToken = resetToken;
    }
    sendSuccess(res, data);
  } catch (err) {
    next(err);
  }
}

export async function resetPassword(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { token, password } = req.body;
    await authService.resetPassword(token, password);
    sendSuccess(res, null, { message: "Şifre güncellendi." });
  } catch (err) {
    next(err);
  }
}
