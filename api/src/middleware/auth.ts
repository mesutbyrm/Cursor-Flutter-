import { NextFunction, Request, Response } from "express";
import { verifyAccessToken } from "../utils/jwt";
import { sendError } from "../utils/response";
import { ErrorCodes } from "../utils/errors";

export interface AuthenticatedRequest extends Request {
  user?: {
    id: number;
    uuid: string;
    email: string;
  };
}

export function authenticate(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    sendError(
      res,
      401,
      ErrorCodes.UNAUTHORIZED,
      "Yetkilendirme gerekli. Bearer token gönderin."
    );
    return;
  }

  const token = header.slice(7);
  try {
    const payload = verifyAccessToken(token);
    req.user = {
      id: payload.sub,
      uuid: payload.uuid,
      email: payload.email,
    };
    next();
  } catch {
    sendError(
      res,
      401,
      ErrorCodes.UNAUTHORIZED,
      "Geçersiz veya süresi dolmuş erişim tokenı."
    );
  }
}
