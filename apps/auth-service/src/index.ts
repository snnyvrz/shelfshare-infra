import express from "express";
import { router } from "@auth/routes/auth.routes";
import { connectMongo } from "@auth/db/auth.db";
import { getJwtSecret } from "@auth/config/auth.config";

const app = express();
const port = 3030;

app.use(express.json());
app.use("/api/auth", router);

async function bootstrap() {
    getJwtSecret();
    await connectMongo();
    app.listen(port, () => {
        console.log(`Auth service listening on port ${port}`);
    });
}

bootstrap().catch((err) => {
    console.error("Failed to start auth-service:", err);
    process.exit(1);
});
