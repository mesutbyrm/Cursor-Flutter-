import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface SocialResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

// Feature 26: Following System
class FollowingService {
  async follow(userId: string, targetUserId: string) {
    if (userId === targetUserId) {
      throw new Error('Kendinizi takip edemezsiniz');
    }

    return prisma.userFollow.create({
      data: { followerId: userId, followingId: targetUserId },
      include: { following: true },
    });
  }

  async unfollow(userId: string, targetUserId: string) {
    return prisma.userFollow.delete({
      where: { followerId_followingId: { followerId: userId, followingId: targetUserId } },
    });
  }

  async getFollowing(userId: string, limit: number = 20, offset: number = 0) {
    return prisma.userFollow.findMany({
      where: { followerId: userId },
      include: { following: true },
      take: limit,
      skip: offset,
      orderBy: { followedAt: 'desc' },
    });
  }

  async getFollowers(userId: string, limit: number = 20, offset: number = 0) {
    return prisma.userFollow.findMany({
      where: { followingId: userId },
      include: { follower: true },
      take: limit,
      skip: offset,
      orderBy: { followedAt: 'desc' },
    });
  }

  async isFollowing(userId: string, targetUserId: string) {
    const follow = await prisma.userFollow.findUnique({
      where: { followerId_followingId: { followerId: userId, followingId: targetUserId } },
    });
    return !!follow;
  }
}

// Feature 27: Blocking System
class BlockingService {
  async block(userId: string, targetUserId: string, reason?: string) {
    if (userId === targetUserId) {
      throw new Error('Kendinizi engelleyemezsiniz');
    }

    await prisma.userFollow.deleteMany({
      where: { OR: [
        { followerId: userId, followingId: targetUserId },
        { followerId: targetUserId, followingId: userId },
      ]},
    });

    return prisma.userBlock.create({
      data: { blockerId: userId, blockedId: targetUserId, reason },
      include: { blocked: true },
    });
  }

  async unblock(userId: string, targetUserId: string) {
    return prisma.userBlock.delete({
      where: { blockerId_blockedId: { blockerId: userId, blockedId: targetUserId } },
    });
  }

  async getBlockedUsers(userId: string) {
    return prisma.userBlock.findMany({
      where: { blockerId: userId },
      include: { blocked: true },
    });
  }

  async isBlocked(userId: string, targetUserId: string) {
    const block = await prisma.userBlock.findUnique({
      where: { blockerId_blockedId: { blockerId: userId, blockedId: targetUserId } },
    });
    return !!block;
  }
}

const followingService = new FollowingService();
const blockingService = new BlockingService();

// Feature 26: Following endpoints
router.post('/follow/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;

    const follow = await followingService.follow(userId, targetUserId);

    res.json({
      ok: true,
      data: follow,
    } as SocialResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.delete('/follow/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;

    await followingService.unfollow(userId, targetUserId);

    res.json({
      ok: true,
      data: { unfollowed: true },
    } as SocialResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.get('/following', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    const following = await followingService.getFollowing(userId, limit, offset);

    res.json({
      ok: true,
      data: { following },
    } as SocialResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.get('/followers', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    const followers = await followingService.getFollowers(userId, limit, offset);

    res.json({
      ok: true,
      data: { followers },
    } as SocialResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.get('/is-following/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;

    const following = await followingService.isFollowing(userId, targetUserId);

    res.json({
      ok: true,
      data: { following },
    } as SocialResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

// Feature 27: Blocking endpoints
router.post('/block/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;
    const { reason } = req.body as { reason?: string };

    const block = await blockingService.block(userId, targetUserId, reason);

    res.json({
      ok: true,
      data: block,
    } as SocialResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.delete('/block/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;

    await blockingService.unblock(userId, targetUserId);

    res.json({
      ok: true,
      data: { unblocked: true },
    } as SocialResponse);
  } catch (error: any) {
    res.status(400).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.get('/blocked-users', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;

    const blockedUsers = await blockingService.getBlockedUsers(userId);

    res.json({
      ok: true,
      data: { blockedUsers },
    } as SocialResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

router.get('/is-blocked/:targetUserId', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { targetUserId } = req.params;

    const blocked = await blockingService.isBlocked(userId, targetUserId);

    res.json({
      ok: true,
      data: { blocked },
    } as SocialResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as SocialResponse);
  }
});

export default router;
