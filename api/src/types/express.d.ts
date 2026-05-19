import "express";

declare module "express-serve-static-core" {
  interface Request {
    /** JWT `sub` — `requireAuth` sonrası dolu */
    userId?: string;
  }
}
