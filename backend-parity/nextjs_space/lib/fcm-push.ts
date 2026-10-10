/**
 * FCM HTTP v1 (Firebase Admin SDK) — canlifal.com full-source'a kopyalanacak şablon.
 * Kimlik: GOOGLE_APPLICATION_CREDENTIALS veya FIREBASE_SERVICE_ACCOUNT_JSON (base64).
 *
 * Prisma: UserDevice (userId, token, platform) — mobil POST /api/user/device-token
 */

import prisma from '@/lib/db'

export interface FcmPushPayload {
  title: string
  body: string
  type: string
  targetPath?: string
  targetId?: string
  urgent?: boolean
}

type FirebaseMessaging = import('firebase-admin/messaging').Messaging

let messagingPromise: Promise<FirebaseMessaging | null> | null = null

async function getMessaging(): Promise<FirebaseMessaging | null> {
  if (messagingPromise) return messagingPromise
  messagingPromise = (async () => {
    try {
      const admin = await import('firebase-admin')
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        })
      }
      return admin.messaging()
    } catch (e) {
      console.error('[fcm-push] Admin SDK init failed:', e)
      return null
    }
  })()
  return messagingPromise
}

function dataPayload(payload: FcmPushPayload): Record<string, string> {
  return {
    type: payload.type || 'general',
    targetPath: payload.targetPath || '',
    targetId: payload.targetId || '',
    title: payload.title,
    body: payload.body,
  }
}

function androidConfig(payload: FcmPushPayload) {
  const channelId = payload.urgent ? 'canlifal_urgent' : 'canlifal_messages'
  return {
    priority: payload.urgent ? ('high' as const) : ('normal' as const),
    notification: {
      channelId,
      sound: 'default',
    },
  }
}

export async function sendFcmToUser(
  userId: string,
  payload: FcmPushPayload,
): Promise<boolean> {
  const messaging = await getMessaging()
  if (!messaging) return false

  const devices = await prisma.userDevice.findMany({
    where: { userId },
    select: { token: true },
  })
  const tokens = devices.map((d) => d.token).filter((t) => t && t.length > 20)
  if (!tokens.length) {
    console.warn('[fcm-push] no tokens for user', userId)
    return false
  }

  try {
    const res = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: dataPayload(payload),
      android: androidConfig(payload),
    })
    const invalid = res.responses
      .map((r, i) => (!r.success ? tokens[i] : null))
      .filter(Boolean) as string[]
    if (invalid.length) {
      await prisma.userDevice.deleteMany({ where: { token: { in: invalid } } })
    }
    return res.successCount > 0
  } catch (e) {
    console.error('[fcm-push] send failed:', e)
    return false
  }
}

export async function sendFcmToMany(
  userIds: string[],
  payload: FcmPushPayload,
): Promise<boolean> {
  if (!userIds.length) return false
  let ok = false
  for (const id of userIds) {
    if (await sendFcmToUser(id, payload)) ok = true
  }
  return ok
}
