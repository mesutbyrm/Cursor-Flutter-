export async function resolveParams<T extends Record<string, string>>(
  params: Promise<T> | T,
): Promise<T> {
  return Promise.resolve(params)
}
