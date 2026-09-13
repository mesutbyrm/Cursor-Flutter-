/** Geçici DM "yazıyor" durumu (tek pod; çoklu instance için Redis gerekir). */
const typingByPair = new Map<string, { userId: string; until: number }>()

function pairKey(conversationId: string, userId: string) {
  return `${conversationId}:${userId}`
}

export function setDmTyping(conversationId: string, userId: string, typing: boolean) {
  const key = pairKey(conversationId, userId)
  if (!typing) {
    typingByPair.delete(key)
    return
  }
  typingByPair.set(key, { userId, until: Date.now() + 8000 })
}

export function isPeerTyping(conversationId: string, selfUserId: string): boolean {
  const now = Date.now()
  for (const [key, entry] of typingByPair.entries()) {
    if (!key.startsWith(`${conversationId}:`)) continue
    if (entry.userId === selfUserId) continue
    if (entry.until < now) {
      typingByPair.delete(key)
      continue
    }
    return true
  }
  return false
}
