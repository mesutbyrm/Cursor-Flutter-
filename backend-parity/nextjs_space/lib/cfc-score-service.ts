type PrismaClient = {
  cfcScoreLog: {
    create: (args: { data: Record<string, unknown> }) => Promise<unknown>
  }
  cfcParticipant: {
    updateMany: (args: {
      where: Record<string, unknown>
      data: Record<string, unknown>
    }) => Promise<unknown>
  }
}

export async function recordCfcScoreDelta(
  prisma: PrismaClient,
  input: {
    contestId: string
    userId?: string | null
    agencyId?: string | null
    roomId?: string | null
    metric: string
    delta: number
    reason?: string | null
  },
) {
  const { contestId, userId, agencyId, roomId, metric, delta, reason } = input
  await prisma.cfcScoreLog.create({
    data: {
      contestId,
      userId: userId ?? null,
      agencyId: agencyId ?? null,
      roomId: roomId ?? null,
      metric,
      delta,
      reason: reason ?? null,
    },
  })
  if (userId && Number.isFinite(delta) && delta !== 0) {
    await prisma.cfcParticipant.updateMany({
      where: { contestId, userId },
      data: { score: { increment: delta } },
    })
  }
}
