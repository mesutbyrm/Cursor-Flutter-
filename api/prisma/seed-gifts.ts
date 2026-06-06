import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const gifts = [
  {
    slug: "gul",
    name: "Gül",
    icon: "/gifts/icons/rose.png",
    animation: "lottie:rose",
    animationType: "lottie",
    price: 10,
    rarity: "common",
    platform: "all",
    sound: "common",
    sortOrder: 1,
  },
  {
    slug: "kalp",
    name: "Kalp",
    icon: "/gifts/icons/heart.png",
    animation: "lottie:heart",
    animationType: "lottie",
    price: 20,
    rarity: "common",
    platform: "all",
    sound: "common",
    sortOrder: 2,
  },
  {
    slug: "yildiz",
    name: "Yıldız",
    icon: "/gifts/icons/star.png",
    animation: "lottie:star",
    animationType: "lottie",
    price: 50,
    rarity: "rare",
    platform: "mobile",
    sound: "rare",
    sortOrder: 3,
  },
  {
    slug: "tac",
    name: "Taç",
    icon: "/gifts/icons/crown.png",
    animation: "lottie:crown",
    animationType: "lottie",
    price: 100,
    rarity: "epic",
    platform: "mobile",
    sound: "epic",
    sortOrder: 4,
  },
  {
    slug: "roket",
    name: "Roket",
    icon: "/gifts/icons/rocket.png",
    animation: "lottie:car",
    animationType: "lottie",
    price: 250,
    rarity: "legendary",
    platform: "mobile",
    sound: "legendary",
    sortOrder: 5,
  },
  {
    slug: "elmas",
    name: "Elmas",
    icon: "/gifts/icons/diamond.png",
    animation: "rive:diamond",
    animationType: "rive",
    price: 500,
    rarity: "legendary",
    platform: "mobile",
    sound: "legendary",
    sortOrder: 6,
  },
  {
    slug: "galaksi",
    name: "Galaksi",
    icon: "/gifts/icons/galaxy.png",
    animation: "svga:galaxy",
    animationType: "svga",
    price: 1000,
    rarity: "mythic",
    platform: "mobile",
    sound: "mythic",
    sortOrder: 7,
  },
  {
    slug: "web_rose",
    name: "Gül (Web)",
    icon: "/gifts/icons/rose.png",
    animation: null,
    animationType: "none",
    price: 10,
    rarity: "common",
    platform: "web",
    sound: null,
    sortOrder: 10,
  },
  {
    slug: "web_coin",
    name: "Jeton (Web)",
    icon: "/gifts/icons/coin.png",
    animation: null,
    animationType: "none",
    price: 5,
    rarity: "common",
    platform: "web",
    sound: null,
    sortOrder: 11,
  },
];

async function main() {
  for (const g of gifts) {
    await prisma.gift.upsert({
      where: { slug: g.slug },
      create: g,
      update: {
        name: g.name,
        icon: g.icon,
        animation: g.animation,
        animationType: g.animationType,
        price: g.price,
        rarity: g.rarity,
        platform: g.platform,
        sound: g.sound,
        sortOrder: g.sortOrder,
        enabled: true,
      },
    });
  }
  console.log(`Seeded ${gifts.length} gifts`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
