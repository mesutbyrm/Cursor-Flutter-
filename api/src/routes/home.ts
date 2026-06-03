import { Router } from "express";
import { ok } from "../lib/response";

const seedBanners = [
  {
    id: "banner-ai-fal",
    title: "Bugün evren sana ne söylüyor?",
    subtitle: "Yapay zeka destekli fal deneyimi",
    ctaLabel: "AI FAL",
    ctaRoute: "/fortune",
    imageUrl: "https://canlifal.com/apple-touch-icon.png",
    gradient: ["#2A1548", "#7B4DFF"],
    quickActions: [
      { id: "kahve", label: "Kahve Falı", route: "/fortune/kahve-fali" },
      { id: "katina", label: "Katina Falı", route: "/fortune/katina-fali" },
      { id: "dogum", label: "Doğum Haritası", route: "/fortune/dogum-haritasi" },
      { id: "ruya", label: "Rüya Yorumu", route: "/fortune/ruya-yorumu" },
    ],
  },
  {
    id: "banner-live",
    title: "Canlı falcılar şimdi yayında",
    subtitle: "Anında bağlan, sorularını sor",
    ctaLabel: "Canlıya Git",
    ctaRoute: "/live",
    imageUrl: "https://canlifal.com/favicon.ico",
    gradient: ["#1A0F3D", "#FE2C55"],
  },
];

const seedAdvisors = [
  {
    id: "adv-1",
    name: "Meryem H.",
    category: "Kahve Uzmanı",
    avatarUrl: "https://canlifal.com/apple-touch-icon.png",
    isOnline: true,
    rating: 4.9,
    viewerCount: 1200,
    specialties: ["kahve-fali"],
  },
  {
    id: "adv-2",
    name: "Ayşe K.",
    category: "Tarot",
    avatarUrl: "https://canlifal.com/favicon.ico",
    isOnline: true,
    rating: 4.7,
    viewerCount: 860,
    specialties: ["tarot"],
  },
];

const seedGames = [
  {
    id: "wheel",
    title: "Çarkıfelek",
    icon: "🎡",
    route: "/fortune",
    accentColor: "#FFD700",
  },
  {
    id: "daily-reward",
    title: "Günlük Ödül",
    icon: "🎁",
    route: "/fortune/gunluk-fal",
    accentColor: "#7B4DFF",
  },
  {
    id: "treasure",
    title: "Hazine Sandığı",
    icon: "💎",
    route: "/jeton-store",
    accentColor: "#25F4EE",
  },
  {
    id: "fortune-cards",
    title: "Fal Kartları",
    icon: "🃏",
    route: "/fortune",
    accentColor: "#B388FF",
  },
  {
    id: "missions",
    title: "Günlük Görevler",
    icon: "✅",
    route: "/profile",
    accentColor: "#3DFF6E",
  },
];

export const homeRouter = Router();

homeRouter.get("/banners", async (_req, res) => {
  return ok(res, { items: seedBanners });
});

homeRouter.get("/advisors/online", async (_req, res) => {
  return ok(res, { items: seedAdvisors });
});

homeRouter.get("/games", async (_req, res) => {
  return ok(res, { items: seedGames });
});

homeRouter.get("/daily-rewards", async (_req, res) => {
  return ok(res, {
    items: [
      {
        id: "daily-1",
        title: "Günlük giriş ödülü",
        description: "Her gün uygulamaya gir, jeton kazan",
        claimed: false,
        rewardJeton: 50,
        route: "/fortune/gunluk-fal",
      },
    ],
  });
});
