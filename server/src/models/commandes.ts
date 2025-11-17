import mongoose, { Document, Schema } from "mongoose";

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

const commandeSchema = new Schema<ICommande>({
  client: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  plats: [{
    plat: {
      type: Schema.Types.ObjectId,
      ref: 'Plat',
      required: true
    },
    quantity: {
      type: Number,
      required: true,
      min: [1, "La quantité minimale est 1"]
    },
    price: {
      type: Number,
      required: true,
      min: [0, "Le prix ne peut pas être négatif"]
    }
  }],
  totalAmount: {
    type: Number,
    required: true,
    min: [0, "Le montant total ne peut pas être négatif"]
  },
  status: {
    type: String,
    enum: ['en_attente', 'en_preparation', 'en_livraison', 'livrée', 'annulée'],
    default: 'en_attente'
  },
  deliveryAddress: {
    type: String,
    required: [true, "L'adresse de livraison est obligatoire"],
    maxlength: [300, "L'adresse ne peut pas dépasser 300 caractères"]
  },
  deliveryPhone: {
    type: String,
    required: [true, "Le téléphone de livraison est obligatoire"],
    match: [/^\+?[0-9]{6,15}$/, "Format de téléphone invalide"]
  },
  notes: {
    type: String,
    maxlength: [500, "Les notes ne peuvent pas dépasser 500 caractères"]
  },
  cuisinier: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  estimatedDeliveryTime: {
    type: Date
  },
  actualDeliveryTime: {
    type: Date
  }
}, {
  timestamps: true
});

commandeSchema.index({ client: 1, createdAt: -1 });
commandeSchema.index({ cuisinier: 1, status: 1 });
commandeSchema.index({ status: 1, createdAt: -1 });

export const Commande = mongoose.model<ICommande>("Commande", commandeSchema);