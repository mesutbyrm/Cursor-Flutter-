import { Router } from "express";
import { requireAuth } from "../middleware/requireAuth";
import { requireStaff } from "../middleware/requireStaff";
import { ok } from "../lib/response";
import { jsonError } from "../lib/jsonError";
import {
  activeCatalogPayload,
  assignSiteAnimation,
  bulkAssignSiteAnimation,
  createSiteAnimation,
  getSiteAnimationDefaults,
  getSiteAnimationStats,
  getUserSiteAnimationAssignments,
  listSiteAnimations,
  saveSiteAnimationDefaults,
  updateSiteAnimation,
} from "../lib/siteAnimationStore";

export const siteAnimationsRouter = Router();

/** GET /api/site-animations/active — mobil runtime katalog */
siteAnimationsRouter.get("/site-animations/active", async (_req, res) => {
  const payload = await activeCatalogPayload();
  return ok(res, payload);
});

/** GET /api/admin/site-animations */
siteAnimationsRouter.get(
  "/admin/site-animations",
  requireAuth,
  requireStaff,
  async (_req, res) => ok(res, { animations: await listSiteAnimations() }),
);

/** POST /api/admin/site-animations */
siteAnimationsRouter.post(
  "/admin/site-animations",
  requireAuth,
  requireStaff,
  async (req, res) => ok(res, await createSiteAnimation(req.body ?? {})),
);

/** PATCH /api/admin/site-animations/:id */
siteAnimationsRouter.patch(
  "/admin/site-animations/:id",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const updated = await updateSiteAnimation(req.params.id, req.body ?? {});
    if (!updated) return jsonError(res, 404, "Animasyon bulunamadı");
    return ok(res, updated);
  },
);

/** GET /api/admin/site-animations/stats */
siteAnimationsRouter.get(
  "/admin/site-animations/stats",
  requireAuth,
  requireStaff,
  async (_req, res) => ok(res, await getSiteAnimationStats()),
);

/** GET /api/admin/site-animations/defaults */
siteAnimationsRouter.get(
  "/admin/site-animations/defaults",
  requireAuth,
  requireStaff,
  async (_req, res) => ok(res, await getSiteAnimationDefaults()),
);

/** PUT /api/admin/site-animations/defaults */
siteAnimationsRouter.put(
  "/admin/site-animations/defaults",
  requireAuth,
  requireStaff,
  async (req, res) =>
    ok(res, await saveSiteAnimationDefaults((req.body ?? {}) as Record<string, string>)),
);

/** POST /api/admin/site-animations/assign */
siteAnimationsRouter.post(
  "/admin/site-animations/assign",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const body = req.body ?? {};
    const userId = String(body.userId ?? "");
    const slot = String(body.slot ?? "");
    if (!userId || !slot) {
      return jsonError(res, 400, "userId ve slot gerekli");
    }
    const result = await assignSiteAnimation({
      userId,
      slot,
      animationId: body.animationId ?? null,
      expiresAt: body.expiresAt ?? null,
    });
    return ok(res, result);
  },
);

/** POST /api/admin/site-animations/bulk-assign */
siteAnimationsRouter.post(
  "/admin/site-animations/bulk-assign",
  requireAuth,
  requireStaff,
  async (req, res) => {
    const body = req.body ?? {};
    const userIds = Array.isArray(body.userIds) ? body.userIds.map(String) : [];
    const slot = String(body.slot ?? "");
    const animationId = String(body.animationId ?? "");
    if (!userIds.length || !slot || !animationId) {
      return jsonError(res, 400, "userIds, slot ve animationId gerekli");
    }
    await bulkAssignSiteAnimation({
      userIds,
      slot,
      animationId,
      expiresAt: body.expiresAt ?? null,
    });
    return ok(res, { assigned: userIds.length });
  },
);

/** GET /api/admin/site-animations/user/:userId */
siteAnimationsRouter.get(
  "/admin/site-animations/user/:userId",
  requireAuth,
  requireStaff,
  async (req, res) =>
    ok(res, await getUserSiteAnimationAssignments(req.params.userId)),
);
