import { NextRequest, NextResponse } from 'next/server'
import { callStreamRoute } from '@/lib/video-stream-parity'

const FORTUNE_REQUESTS = '@/app/api/video-streams/[streamId]/fortune-requests/route'

function streamIdFromBody(body: Record<string, unknown>, req: NextRequest): string {
  const fromBody =
    (body.streamId ?? body.stream_id ?? body.videoStreamId)?.toString().trim() ?? ''
  if (fromBody) return fromBody
  return req.nextUrl.searchParams.get('streamId')?.trim() ?? ''
}

export async function liveFalRequestsList(req: NextRequest) {
  const streamId = streamIdFromBody({}, req)
  if (!streamId) {
    return NextResponse.json({ error: 'streamId gerekli' }, { status: 400 })
  }
  return callStreamRoute(req, streamId, FORTUNE_REQUESTS, 'GET')
}

export async function liveFalRequestCreate(req: NextRequest) {
  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
  const streamId = streamIdFromBody(body, req)
  if (!streamId) {
    return NextResponse.json({ error: 'streamId gerekli' }, { status: 400 })
  }
  const forwarded = new NextRequest(req.url, {
    method: 'POST',
    headers: req.headers,
    body: JSON.stringify(body),
  })
  return callStreamRoute(forwarded, streamId, FORTUNE_REQUESTS, 'POST')
}

export async function liveFalRequestUpdate(req: NextRequest, requestId: string) {
  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
  const streamId = streamIdFromBody(body, req)
  if (!streamId) {
    return NextResponse.json({ error: 'streamId gerekli' }, { status: 400 })
  }
  const patchBody = {
    ...body,
    requestId,
    action: body.action ?? body.status,
  }
  const forwarded = new NextRequest(req.url, {
    method: 'PATCH',
    headers: req.headers,
    body: JSON.stringify(patchBody),
  })
  return callStreamRoute(forwarded, streamId, FORTUNE_REQUESTS, 'PATCH')
}

export async function liveFalRequestComplete(req: NextRequest, requestId: string) {
  const body = (await req.json().catch(() => ({}))) as Record<string, unknown>
  const streamId = streamIdFromBody(body, req)
  if (!streamId) {
    return NextResponse.json({ error: 'streamId gerekli' }, { status: 400 })
  }
  const forwarded = new NextRequest(req.url, {
    method: 'PATCH',
    headers: req.headers,
    body: JSON.stringify({ action: 'complete', requestId, ...body }),
  })
  return callStreamRoute(forwarded, streamId, FORTUNE_REQUESTS, 'PATCH')
}
