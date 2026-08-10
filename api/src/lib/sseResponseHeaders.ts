import type { Response } from "express";

/** Canonical SSE response headers — nginx/Envoy buffering disable + no CDN cache. */
export function applySseResponseHeaders(res: Response): void {
  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders?.();
}
