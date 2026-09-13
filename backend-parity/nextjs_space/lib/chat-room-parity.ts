import { NextRequest } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'

type RoomCtx = {
  params: Promise<{ roomId: string }> | { roomId: string }
}

export async function roomIdFrom(context: RoomCtx): Promise<string> {
  const { roomId } = await resolveParams(context.params)
  return roomId
}

export async function forwardJson(
  req: NextRequest,
  method: string,
  body: Record<string, unknown>,
): Promise<NextRequest> {
  return new NextRequest(req.url, {
    method,
    headers: req.headers,
    body: JSON.stringify(body),
  })
}

export async function callRoomRoute(
  req: NextRequest,
  roomId: string,
  importPath: string,
  handler: string,
  extraParams: Record<string, string> = {},
) {
  const mod = await import(importPath)
  const fn = mod[handler] as (
    r: NextRequest,
    c: { params: Promise<Record<string, string>> },
  ) => Promise<Response>
  return fn(req, {
    params: Promise.resolve({ roomId, ...extraParams }),
  })
}
