// Unified Push — FCM-only geçiş şablonu (canlifal.com full-source)
//
// PUSH_PROVIDER=fcm  → lib/fcm-push.ts (UserDevice tokenları)
// PUSH_PROVIDER=onesignal → lib/onesignal.ts (legacy)
// ONESIGNAL_SEND_DISABLED=1 → OneSignal dalı no-op (çift gönderim önleme)

import {
  sendPushToUser as oneSignalSendToUser,
  sendPushToMultipleUsers as oneSignalSendToMany,
} from '@/lib/onesignal'
import { sendFcmToUser, sendFcmToMany } from '@/lib/fcm-push'

export interface UnifiedPushPayload {
  title: string
  body: string
  type: string
  targetPath?: string
  targetId?: string
  urgent?: boolean
}

export const PUSH_PROVIDER =
  (process.env.PUSH_PROVIDER || 'onesignal').toLowerCase() === 'fcm'
    ? ('fcm' as const)
    : ('onesignal' as const)

const onesignalDisabled = process.env.ONESIGNAL_SEND_DISABLED === '1'

export async function sendPush(
  userId: string,
  payload: UnifiedPushPayload,
): Promise<boolean> {
  try {
    if (PUSH_PROVIDER === 'fcm') {
      return await sendFcmToUser(userId, payload)
    }
    if (onesignalDisabled) {
      console.warn('[push] OneSignal disabled, skip sendPush')
      return false
    }
    return await oneSignalSendToUser(userId, payload)
  } catch (err) {
    console.error('[push] sendPush failed (non-blocking):', err)
    return false
  }
}

export async function sendPushBulk(
  userIds: string[],
  payload: UnifiedPushPayload,
): Promise<boolean> {
  if (!userIds.length) return false
  try {
    if (PUSH_PROVIDER === 'fcm') {
      return await sendFcmToMany(userIds, payload)
    }
    if (onesignalDisabled) return false
    return await oneSignalSendToMany(userIds, payload)
  } catch (err) {
    console.error('[push] sendPushBulk failed (non-blocking):', err)
    return false
  }
}
