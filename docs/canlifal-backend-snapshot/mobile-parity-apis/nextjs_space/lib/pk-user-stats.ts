import prisma from '@/lib/db'
import { loadPkUsers } from '@/lib/pk-match'

export async function computePkStatsForUser(userId: string) {
  const battles = await prisma.pKBattle.findMany({
    where: {
      status: 'completed',
      OR: [{ user1Id: userId }, { user2Id: userId }],
    },
    select: {
      user1Id: true,
      user2Id: true,
      winnerId: true,
      isDraw: true,
      score1: true,
      score2: true,
    },
  })

  let wins = 0
  let losses = 0
  let draws = 0
  let totalScore = 0
  let bestScore = 0

  for (const b of battles) {
    const isHost = b.user1Id === userId
    const my = isHost ? b.score1 || 0 : b.score2 || 0
    totalScore += my
    if (my > bestScore) bestScore = my
    if (b.isDraw || !b.winnerId) {
      draws++
    } else if (b.winnerId === userId) {
      wins++
    } else {
      losses++
    }
  }

  const total = wins + losses + draws
  const winRate = total === 0 ? 0 : Math.round((wins / total) * 100)

  return { wins, losses, draws, totalScore, bestScore, streak: 0, winRate }
}

export async function listPkHistoryForUser(userId: string, page: number, limit: number) {
  const skip = Math.max(0, (page - 1) * limit)
  const take = Math.min(50, Math.max(1, limit))

  const battles = await prisma.pKBattle.findMany({
    where: {
      status: 'completed',
      OR: [{ user1Id: userId }, { user2Id: userId }],
    },
    orderBy: { endedAt: 'desc' },
    skip,
    take,
  })

  const users = await loadPkUsers(battles)
  const history = battles.map((b) => {
    const isHost = b.user1Id === userId
    const oppId = isHost ? b.user2Id : b.user1Id
    const opp = users.get(oppId)
    const myScore = isHost ? b.score1 || 0 : b.score2 || 0
    const opponentScore = isHost ? b.score2 || 0 : b.score1 || 0
    let result = 'draw'
    if (b.winnerId === userId) result = 'win'
    else if (b.winnerId && b.winnerId !== userId) result = 'loss'
    else if (b.isDraw) result = 'draw'

    const ended = b.endedAt ? new Date(b.endedAt).toISOString() : null
    return {
      id: b.id,
      matchId: b.id,
      result,
      mode: b.mode || '1v1',
      opponentName: opp?.name ?? null,
      myScore,
      opponentScore,
      coins: myScore,
      durationSec: b.duration || 0,
      at: ended,
      createdAt: ended,
      endedAt: ended,
    }
  })

  return history
}
