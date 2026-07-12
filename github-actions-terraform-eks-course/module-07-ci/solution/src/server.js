import express from "express";
import { fileURLToPath } from "node:url";

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const APP_MESSAGE = process.env.APP_MESSAGE || "Course API — Module 07 CI";

app.get("/", (_req, res) => {
  res.json({
    message: APP_MESSAGE,
    module: "07-ci",
    region: process.env.AWS_REGION || "us-east-1",
  });
});

app.get("/health", (_req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "course-api",
  });
});

const isMain = process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`course-api listening on port ${PORT}`);
  });
}

export default app;
