import { Router } from 'express';
import { requireAuth } from '../middleware/requireAuth';

export const reportsRouter = Router();

reportsRouter.use(requireAuth);

reportsRouter.post('/', async (req, res) => {
  const { targetType, targetId, reason, details } = req.body as {
    targetType?: string;
    targetId?: string;
    reason?: string;
    details?: string;
  };
  if (!targetType?.trim() || !targetId?.trim() || !reason?.trim()) {
    res.status(400).json({ error: 'targetType, targetId ve reason gerekli' });
    return;
  }
  res.status(201).json({
    report: {
      id: `report-${Date.now()}`,
      targetType: targetType.trim(),
      targetId: targetId.trim(),
      reason: reason.trim(),
      details: details?.trim() ?? null,
      status: 'pending',
      createdAt: new Date().toISOString(),
    },
  });
});
