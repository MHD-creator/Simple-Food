import type { Request, Response } from "express";
export declare const commandeValidation: import("express-validator").ValidationChain[];
export declare const createCommande: (req: Request, res: Response) => Promise<void>;
export declare const getCommandes: (req: Request, res: Response) => Promise<void>;
export declare const getCommandeById: (req: Request, res: Response) => Promise<void>;
export declare const updateCommandeStatus: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=commandeController.d.ts.map