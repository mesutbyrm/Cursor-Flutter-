import { Request, Response } from "express";
import { ErrorCodes } from "../utils/errors";
import { sendError } from "../utils/response";

export function notFoundHandler(_req: Request, res: Response): void {
  sendError(res, 404, ErrorCodes.NOT_FOUND, "İstenen kaynak bulunamadı.");
}
