/** Google ID token doğrulama (SQL kullanıcı eşlemesi için). */

export type GoogleTokenPayload = {
  sub: string;
  email?: string;
  email_verified?: string | boolean;
  name?: string;
  picture?: string;
};

/** Mobil `serverClientId` = Web OAuth client; sunucuda GOOGLE_CLIENT_ID veya GOOGLE_SERVER_CLIENT_ID. */
export function googleAllowedClientIds(): string[] {
  const parts = [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_SERVER_CLIENT_ID,
    process.env.GOOGLE_CLIENT_IDS,
  ]
    .filter((v): v is string => typeof v === "string" && v.trim().length > 0)
    .flatMap((v) => v.split(","));

  const seen = new Set<string>();
  const ids: string[] = [];
  for (const raw of parts) {
    const id = raw.trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
  }
  return ids;
}

export function isGoogleAudienceAllowed(
  tokenInfo: Record<string, string>,
  allowed: string[],
): boolean {
  if (allowed.length === 0) return true;
  const candidates = [tokenInfo.aud, tokenInfo.azp].filter(
    (v): v is string => typeof v === "string" && v.length > 0,
  );
  return candidates.some((c) => allowed.includes(c));
}

export async function verifyGoogleIdToken(
  idToken: string,
): Promise<GoogleTokenPayload | null> {
  if (!idToken.trim()) return null;

  const allowed = googleAllowedClientIds();
  const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
  const res = await fetch(url);
  if (!res.ok) {
    console.warn("Google tokeninfo failed", res.status);
    return null;
  }

  const data = (await res.json()) as Record<string, string>;
  if (!data.sub) return null;

  if (!isGoogleAudienceAllowed(data, allowed)) {
    console.warn(
      "Google token aud/azp mismatch",
      { aud: data.aud, azp: data.azp, allowedCount: allowed.length },
    );
    return null;
  }

  return {
    sub: data.sub,
    email: data.email,
    email_verified: data.email_verified,
    name: data.name,
    picture: data.picture,
  };
}
