import mongoose, { Document } from "mongoose";
export interface IPlat extends Document {
    name: string;
    description: string;
    price: number;
    category: string;
    image?: string;
    images?: string[];
    prices?: {
        label: string;
        price: number;
    }[];
    cuisinier: mongoose.Types.ObjectId;
    ingredients: string[];
    available: boolean;
    stock: number;
    promoActive?: boolean;
    promoPercent?: number;
    promoStart?: Date;
    promoEnd?: Date;
    preparationTime: number;
    rating: number;
    ratingCount: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare const Plat: mongoose.Model<IPlat, {}, {}, {}, mongoose.Document<unknown, {}, IPlat, {}, {}> & IPlat & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>;
//# sourceMappingURL=plat_model.d.ts.map