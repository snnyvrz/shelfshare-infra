import type { UserDoc } from "@auth/models/User";
import jwt from "jsonwebtoken";
import { getJwtSecret } from "@auth/config/auth.config";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || 3600;

export const signToken = (user: UserDoc) => {
    if (!user) {
        throw new Error("User is null, cannot sign token");
    }

    return jwt.sign(
        { sub: user._id.toString(), email: user.email },
        getJwtSecret(),
        {
            expiresIn: Number(JWT_EXPIRES_IN),
        }
    );
};
