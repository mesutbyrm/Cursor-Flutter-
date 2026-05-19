import { Response, NextFunction } from "express";
import * as userService from "../services/userService";
import { sendSuccess } from "../utils/response";
import { AuthenticatedRequest } from "../middleware/auth";

export async function me(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await userService.getUserById(req.user!.id);
    sendSuccess(res, { user });
  } catch (err) {
    next(err);
  }
}

export async function updateProfile(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { name, phone, avatarUrl } = req.body;
    const user = await userService.updateProfile(req.user!.id, {
      name,
      phone,
      avatarUrl,
    });
    sendSuccess(res, { user }, { message: "Profil güncellendi." });
  } catch (err) {
    next(err);
  }
}

export async function changePassword(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { currentPassword, newPassword } = req.body;
    await userService.changePassword(
      req.user!.id,
      currentPassword,
      newPassword
    );
    sendSuccess(res, null, {
      message: "Şifre güncellendi. Lütfen tekrar giriş yapın.",
    });
  } catch (err) {
    next(err);
  }
}

export async function deleteAccount(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { password } = req.body;
    await userService.deleteAccount(req.user!.id, password);
    sendSuccess(res, null, { message: "Hesap silindi." });
  } catch (err) {
    next(err);
  }
}

export async function verifyEmail(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await userService.verifyEmail(req.user!.id);
    sendSuccess(res, { user }, { message: "E-posta doğrulandı." });
  } catch (err) {
    next(err);
  }
}
