import type { Request, Response } from "express";
export declare const updateDeliverySettings: (req: Request, res: Response) => Promise<void>;
export declare const changePasswordValidation: import("express-validator").ValidationChain[];
export declare const changePassword: (req: Request, res: Response) => Promise<void>;
export declare const updateKitchenLocation: (req: Request, res: Response) => Promise<void>;
export declare const updateProfile: (req: Request, res: Response) => Promise<void>;
export declare const registerValidation: import("express-validator").ValidationChain[];
export declare const loginValidation: import("express-validator").ValidationChain[];
export declare const register: (req: Request, res: Response) => Promise<void>;
export declare const login: (req: Request, res: Response) => Promise<void>;
export declare const getProfile: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=authController.d.ts.map