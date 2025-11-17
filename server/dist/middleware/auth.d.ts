import type { Request, Response, NextFunction } from "express";
interface JwtPayload {
    userId: string;
    telephone: string;
    role: string;
}
export interface AuthRequest extends Request {
    user: JwtPayload;
}
export declare const authenticate: (req: Request, res: Response, next: NextFunction) => Promise<void>;
export declare const authorize: (...roles: string[]) => (req: Request, res: Response, next: NextFunction) => void;
export {};
//# sourceMappingURL=auth.d.ts.map