import { prisma } from "./prisma";
import { createNotification } from "./notifications";

const FORTUNE_LABELS: Record<string, string> = {
  tarot: "Tarot Falı",
  "kahve-fali": "Kahve Falı",
  "ruya-tabiri": "Rüya Yorumu",
  "el-fali": "El Falı",
  "yildiz-haritasi": "Burç Yorumu",
  "ask-fali": "Aşk Falı",
  "melek-kartlari": "Melek Kartları",
  numeroloji: "Numeroloji",
  katina: "Katina",
  iskambil: "İskambil",
  pendul: "Pendül",
  runik: "Runik",
  "cin-fali": "Cin Falı",
  "evet-hayir": "Evet / Hayır",
  "gunluk-fal": "Günlük Fal",
};

export function fortuneTypeLabel(slug: string, fallback?: string): string {
  return FORTUNE_LABELS[slug] ?? fallback ?? slug.replaceAll("-", " ");
}

export function buildFortuneShareCaption(input: {
  displayName: string;
  fortuneSlug: string;
  fortuneType?: string;
  summary: string;
}): string {
  const label = fortuneTypeLabel(input.fortuneSlug, input.fortuneType);
  const name = input.displayName.trim() || "Bir kullanıcı";
  const teaser =
    input.summary.length > 140
      ? `${input.summary.slice(0, 137)}…`
      : input.summary;
  return [
    `${name} bugün ${label} açtı.`,
    `Yapay zekanın yorumu oldukça dikkat çekici: «${teaser}»`,
    "Sen de kendi falını şimdi aç.",
  ].join("\n");
}

/** Takipçilere fal paylaşımı bildirimi (ilk 200). */
export async function notifyFollowersFortuneShared(input: {
  authorId: string;
  authorName: string;
  postId: string;
  fortuneSlug: string;
  fortuneType?: string;
}) {
  const followers = await prisma.follow.findMany({
    where: { followingId: input.authorId },
    select: { followerId: true },
    take: 200,
  });
  if (followers.length === 0) return;

  const label = fortuneTypeLabel(input.fortuneSlug, input.fortuneType);
  const title = `${input.authorName} yeni bir fal paylaştı`;
  const body = `${label} — akışta görüntüle`;

  await Promise.all(
    followers.map((f) =>
      createNotification({
        userId: f.followerId,
        title,
        body,
        type: "fortune_share",
        targetPath: "/sosyal",
        targetId: input.postId,
      }),
    ),
  );
}
