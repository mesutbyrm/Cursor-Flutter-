import type { Response } from "express";

/** canlifal.com üretim formatı: `{ "error": "..." }` */
export function jsonError(res: Response, status: number, message: string) {
  return res.status(status).json({ error: message });
}
