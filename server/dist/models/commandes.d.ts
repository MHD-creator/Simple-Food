import mongoose, { Document } from "mongoose";
export interface ICommande extends Document {
    client: mongoose.Types.ObjectId;
    plats: Array<{
        plat: mongoose.Types.ObjectId;
        quantity: number;
        price: number;
    }>;
    totalAmount: number;
    status: 'en_attente' | 'en_preparation' | 'en_livraison' | 'livrée' | 'annulée';
    deliveryAddress: string;
    deliveryPhone: string;
    notes?: string;
    cuisinier: mongoose.Types.ObjectId;
    estimatedDeliveryTime?: Date;
    actualDeliveryTime?: Date;
    createdAt: Date;
    updatedAt: Date;
}
export declare const Commande: mongoose.Model<ICommande, {}, {}, {}, mongoose.Document<unknown, {}, ICommande, {}, {}> & ICommande & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>;
//# sourceMappingURL=commandes.d.ts.map