import {
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
  type PutObjectCommandInput,
} from "@aws-sdk/client-s3";
import { randomUUID } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";

const MAX_BYTES = 10 * 1024 * 1024;

export type UploadResult = {
  url: string;
  key: string;
};

function r2Client(): S3Client | null {
  const accountId = process.env.R2_ACCOUNT_ID?.trim();
  const accessKeyId = process.env.R2_ACCESS_KEY_ID?.trim();
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY?.trim();
  if (!accountId || !accessKeyId || !secretAccessKey) return null;
  return new S3Client({
    region: "auto",
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
  });
}

function publicBaseUrl(): string {
  const cdn = process.env.R2_PUBLIC_URL?.trim();
  if (cdn) return cdn.replace(/\/$/, "");
  const bucket = process.env.R2_BUCKET_NAME?.trim() ?? "canlifal-shorts";
  const accountId = process.env.R2_ACCOUNT_ID?.trim();
  if (accountId) {
    return `https://${bucket}.${accountId}.r2.cloudflarestorage.com`;
  }
  return "http://127.0.0.1:3000/uploads/shorts";
}

export async function uploadShortMedia(params: {
  buffer: Buffer;
  contentType: string;
  ext: string;
  folder: "videos" | "thumbnails";
}): Promise<UploadResult> {
  if (params.buffer.length > MAX_BYTES) {
    throw new Error("FILE_TOO_LARGE");
  }

  const key = `shorts/${params.folder}/${randomUUID()}.${params.ext}`;
  const client = r2Client();
  const bucket = process.env.R2_BUCKET_NAME?.trim() ?? "canlifal-shorts";

  if (client) {
    const input: PutObjectCommandInput = {
      Bucket: bucket,
      Key: key,
      Body: params.buffer,
      ContentType: params.contentType,
      CacheControl: "public, max-age=31536000, immutable",
    };
    await client.send(new PutObjectCommand(input));
    return { key, url: `${publicBaseUrl()}/${key}` };
  }

  const localDir = path.join(process.cwd(), "uploads", "shorts", params.folder);
  await fs.mkdir(localDir, { recursive: true });
  const filename = `${randomUUID()}.${params.ext}`;
  const filePath = path.join(localDir, filename);
  await fs.writeFile(filePath, params.buffer);
  return {
    key: `shorts/${params.folder}/${filename}`,
    url: `${publicBaseUrl()}/${params.folder}/${filename}`,
  };
}

export async function getShortMediaObject(key: string): Promise<{
  body: NodeJS.ReadableStream;
  contentType: string;
  contentLength?: number;
} | null> {
  const client = r2Client();
  const bucket = process.env.R2_BUCKET_NAME?.trim() ?? "canlifal-shorts";

  if (client) {
    try {
      const out = await client.send(
        new GetObjectCommand({ Bucket: bucket, Key: key }),
      );
      if (!out.Body) return null;
      return {
        body: out.Body as NodeJS.ReadableStream,
        contentType: out.ContentType ?? "application/octet-stream",
        contentLength: out.ContentLength,
      };
    } catch {
      return null;
    }
  }

  const localPath = path.join(process.cwd(), "uploads", key);
  try {
    const data = await fs.readFile(localPath);
    const { Readable } = await import("node:stream");
    return {
      body: Readable.from(data),
      contentType: key.endsWith(".mp4") ? "video/mp4" : "image/jpeg",
      contentLength: data.length,
    };
  } catch {
    return null;
  }
}

export function storageKeyFromPublicUrl(url: string): string | null {
  const trimmed = url.trim();
  if (!trimmed) return null;
  try {
    const u = new URL(trimmed);
    const p = u.pathname.startsWith("/") ? u.pathname.slice(1) : u.pathname;
    if (p.startsWith("shorts/")) return p;
    const idx = p.indexOf("shorts/");
    if (idx >= 0) return p.slice(idx);
  } catch {
    // ignore
  }
  return null;
}
