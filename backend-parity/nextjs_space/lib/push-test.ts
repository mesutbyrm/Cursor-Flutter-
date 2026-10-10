/**
 * Test push — tanılama ekranı (`POST /api/notifications/test-push`).
 * PUSH_PROVIDER=fcm → FCM; aksi halde OneSignal (legacy).
 */

import { PUSH_PROVIDER, sendPush, type UnifiedPushPayload } from '@/lib/push'
import { sendTestPushDetailed as oneSignalTestDetailed } from '@/lib/onesignal'

export type TestPushResult = {
  ok: boolean
  provider: string
  reason?: string
  response?: unknown
}

export async function sendTestPushDetailed(userId: string): Promise<TestPushResult> {
  if (PUSH_PROVIDER === 'fcm') {
    const payload: UnifiedPushPayload = {
      title: 'Canlifal test',
      body: 'FCM test bildirimi — tanılama ekranı',
      type: 'system',
      targetPath: '/notifications',
      urgent: false,
    }
    const ok = await sendPush(userId, payload)
    return {
      ok,
      provider: 'fcm',
      reason: ok ? undefined : 'FCM gönderilemedi (token yok veya Admin SDK hatası)',
    }
  }
  const legacy = await oneSignalTestDetailed(userId)
  return { ...legacy, provider: 'onesignal' }
}
