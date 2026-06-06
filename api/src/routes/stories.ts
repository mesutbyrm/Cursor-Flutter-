import { Router } from 'express';
import { requireAuth } from '../middleware/requireAuth';

export const storiesRouter = Router();

storiesRouter.use(requireAuth);

/** Hikaye grupları — prod şemasına göre genişletilebilir. */
storiesRouter.get('/', async (_req, res) => {
  res.json({ groups: [] });
});

storiesRouter.post('/', async (req, res) => {
  const { mediaUrl, mediaType, caption } = req.body as {
    mediaUrl?: string;
    mediaType?: string;
    caption?: string;
  };
  if (!mediaUrl?.trim()) {
    res.status(400).json({ error: 'mediaUrl gerekli' });
    return;
  }
  res.status(201).json({
    story: {
      id: `story-${Date.now()}`,
      mediaUrl: mediaUrl.trim(),
      mediaType: mediaType ?? 'image',
      caption: caption ?? null,
      createdAt: new Date().toISOString(),
    },
  });
});
