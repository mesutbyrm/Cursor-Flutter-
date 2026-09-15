import { NextRequest } from 'next/server'
import { getChatRoomsList } from '@/lib/chat-rooms-list-handlers'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  return getChatRoomsList(req)
}
