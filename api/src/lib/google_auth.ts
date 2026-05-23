/** Google ID token doğrulama (SQL kullanıcı eşlemesi için). */

export type GoogleTokenPayload = {
  sub: string;
  email?: string;
  email_verified?: string | boolean;
  name?: string;
  picture?: string;
};

export async function verifyGoogleIdToken(
  idToken: string,
): Promise<GoogleTokenPayload | null> {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim();
  if (!idToken.trim()) return null;

  const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
  const res = await fetch(url);
  if (!res.ok) return null;

  const data = (await res.json()) as Record<string, string>;
  if (clientId && data.aud !== clientId) {
    console.warn("Google token aud mismatch");
    return null;
  }
  if (!data.sub) return null;

  return {
    sub: data.sub,
    email: data.email,
    email_verified: data.email_verified,
    name: data.name,
    picture: data.picture,
  };
}
