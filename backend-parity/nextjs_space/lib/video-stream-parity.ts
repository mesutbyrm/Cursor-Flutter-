import { NextRequest } from 'next/server'
import { resolveParams } from '@/lib/parity-route-params'

type StreamCtx = {
  params: Promise<{ streamId: string }> | { streamId: string }
}

export async function streamIdFrom(context: StreamCtx): Promise<string> {
  const { streamId } = await resolveParams(context.params)
  return streamId
}

export async function callStreamRoute(
  req: NextRequest,
  streamId: string,
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
    params: Promise.resolve({ streamId, ...extraParams }),
  })
}
