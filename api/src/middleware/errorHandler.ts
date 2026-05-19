import { NextFunction, Request, Response } from "express";
import { validationResult } from "express-validator";
import { AppError, ErrorCodes } from "../utils/errors";
import { sendError } from "../utils/response";

export function handleValidation(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    sendError(res, 422, ErrorCodes.VALIDATION, "Doğrulama hatası.", {
      fields: errors.array(),
    });
    return;
  }
  next();
}

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  if (err instanceof AppError) {
    sendError(res, err.statusCode, err.code, err.message, err.details);
    return;
  }

  console.error(err);
  sendError(
    res,
    500,
    ErrorCodes.INTERNAL,
    "Beklenmeyen bir sunucu hatası oluştu."
  );
}
