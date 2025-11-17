import type { Request, Response } from "express";
export declare const platValidation: import("express-validator").ValidationChain[];
export declare const createPlat: (req: Request, res: Response) => Promise<void>;
export declare const getPlats: (req: Request, res: Response) => Promise<void>;
export declare const getPlatById: (req: Request, res: Response) => Promise<void>;
export declare const updatePlat: (req: Request, res: Response) => Promise<void>;
export declare const deletePlat: (req: Request, res: Response) => Promise<void>;
export declare const getMyPlats: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=platController.d.ts.map