import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { getJwtSecret } from "@auth/config/auth.config";

export const authMiddleware = (
    req: Request,
    res: Response,
    next: NextFunction
) => {
    const authHeader = req.get("authorization");
    if (!authHeader) {
        return res
            .status(401)
            .json({ error: "Missing Authorization header" });
    }

    const [scheme, token] = authHeader.split(" ");
    if (scheme !== "Bearer" || !token) {
        return res.status(401).json({ error: "Invalid Authorization format" });
    }

    try {
        const payload = jwt.verify(token, getJwtSecret());

        if (
            typeof payload !== "object" ||
            payload === null ||
            !("sub" in payload) ||
            !("email" in payload)
        ) {
            return res.status(401).json({ error: "Invalid token payload" });
        }

        req.user = {
            id: payload.sub as string,
            email: payload.email as string,
        };
        next();
    } catch {
        return res.status(401).json({ error: "Invalid or expired token" });
    }
};
