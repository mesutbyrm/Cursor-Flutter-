import "dotenv/config";
import "express-async-errors";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { authRouter } from "./routes/auth";
import { usersRouter } from "./routes/users";
import { fail } from "./lib/response";

const app = express();
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") ?? true, credentials: true }));
app.use(express.json({ limit: "512kb" }));

const v1 = express.Router();
v1.get("/health", (_req, res) => {
  res.status(200).json({ success: true, data: { status: "ok" } });
});
v1.use("/auth", authRouter);
v1.use("/users", usersRouter);

app.use("/api/v1", v1);

app.use((_req, res) => {
  return fail(res, 404, "NOT_FOUND", "Endpoint bulunamadı");
});

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  return fail(res, 500, "INTERNAL_ERROR", "Beklenmeyen sunucu hatası");
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => {
  console.log(`Canlifal API http://localhost:${port}/api/v1`);
});
