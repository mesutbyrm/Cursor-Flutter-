import { NextRequest, NextResponse } from 'next/server'
import { authenticateRequest } from '@/lib/mobile-auth'
import { sendTestPushDetailed } from '@/lib/push-test'

export const dynamic = 'force-dynamic'

/** POST /api/notifications/test-push — oturum sahibine test push; ham sonuç (FCM veya OneSignal). */
export async function POST(request: NextRequest) {
  const authUser = await authenticateRequest(request)
  if (!authUser?.id) {
    return NextResponse.json({ error: 'Oturum açmanız gerekiyor' }, { status: 401 })
  }
  const result = await sendTestPushDetailed(authUser.id)
  return NextResponse.json(result, { status: result.ok ? 200 : 502 })
}
