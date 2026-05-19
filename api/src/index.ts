import { validateEnv } from "./config/env";
import { env } from "./config/env";
import { createApp } from "./app";
import { prisma } from "./lib/prisma";

validateEnv();

const app = createApp();

async function main() {
  await prisma.$connect();
  app.listen(env.port, () => {
    console.log(
      `Canlifal API listening on http://localhost:${env.port}${env.apiPrefix}`
    );
  });
}

main().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});

process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  process.exit(0);
});
