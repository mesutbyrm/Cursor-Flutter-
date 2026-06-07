import { Api as TLSSigApi } from "tls-sig-api-v2";

/**
 * Tencent TRTC UserSig — sunucu tarafı.
 * Ortam: TRTC_SDK_APP_ID, TRTC_SECRET_KEY
 */
export function generateTrtcUserSig(
  userId: string,
  expireSeconds = 86_400,
): { sdkAppId: number; userSig: string; userId: string } {
  const sdkAppId = Number(
    process.env.TRTC_SDK_APP_ID ?? process.env.TENCENT_TRTC_SDK_APP_ID ?? 0,
  );
  const secretKey = (
    process.env.TRTC_SECRET_KEY ??
    process.env.TENCENT_TRTC_SECRET_KEY ??
    ""
  ).trim();

  if (!sdkAppId || !secretKey) {
    throw new Error("TRTC_SDK_APP_ID ve TRTC_SECRET_KEY tanımlı değil");
  }

  const api = new TLSSigApi(sdkAppId, secretKey);
  const userSig = api.genUserSig(userId, expireSeconds);
  return { sdkAppId, userSig, userId };
}
