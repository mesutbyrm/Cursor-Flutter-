/** TikTok Login Kit — authorization code → access token → user info */

export type TikTokUserInfo = {
  openId: string;
  unionId?: string;
  displayName?: string;
  avatarUrl?: string;
};

export async function exchangeTikTokCode(
  code: string,
  redirectUri: string,
): Promise<{ accessToken: string; openId: string } | null> {
  const clientKey = process.env.TIKTOK_CLIENT_KEY?.trim();
  const clientSecret = process.env.TIKTOK_CLIENT_SECRET?.trim();
  if (!clientKey || !clientSecret || !code.trim()) return null;

  const tokenRes = await fetch(
    "https://open.tiktokapis.com/v2/oauth/token/",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_key: clientKey,
        client_secret: clientSecret,
        code: code.trim(),
        grant_type: "authorization_code",
        redirect_uri: redirectUri,
      }),
    },
  );
  if (!tokenRes.ok) {
    console.warn("TikTok token exchange failed", await tokenRes.text());
    return null;
  }

  const tokenJson = (await tokenRes.json()) as {
    data?: { access_token?: string; open_id?: string };
  };
  const accessToken = tokenJson.data?.access_token;
  const openId = tokenJson.data?.open_id;
  if (!accessToken || !openId) return null;

  return { accessToken, openId };
}

export async function fetchTikTokUser(
  accessToken: string,
): Promise<TikTokUserInfo | null> {
  const res = await fetch(
    "https://open.tiktokapis.com/v2/user/info/?fields=open_id,union_id,display_name,avatar_url",
    {
      headers: { Authorization: `Bearer ${accessToken}` },
    },
  );
  if (!res.ok) return null;

  const json = (await res.json()) as {
    data?: {
      user?: {
        open_id?: string;
        union_id?: string;
        display_name?: string;
        avatar_url?: string;
      };
    };
  };
  const u = json.data?.user;
  if (!u?.open_id) return null;

  return {
    openId: u.open_id,
    unionId: u.union_id,
    displayName: u.display_name,
    avatarUrl: u.avatar_url,
  };
}
