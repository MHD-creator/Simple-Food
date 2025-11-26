import mongoose, { Document, Schema } from "mongoose";
const platSchema = new Schema({
    name: {
        type: String,
        required: [true, "Le nom du plat est obligatoire"],
        trim: true,
        maxlength: [100, "Le nom ne peut pas dépasser 100 caractères"]
    },
    description: {
        type: String,
        required: [true, "La description est obligatoire"],
        maxlength: [500, "La description ne peut pas dépasser 500 caractères"]
    },
    price: {
        type: Number,
        required: [true, "Le prix est obligatoire"],
        min: [0, "Le prix ne peut pas être négatif"]
    },
    category: {
        type: String,
        required: [true, "La catégorie est obligatoire"],
        enum: ['africain', 'européen', 'asiatique', 'fast-food', 'dessert', 'boisson']
    },
    image: {
        type: String
    },
    images: [{
            type: String,
            trim: true,
        }],
    prices: [{
            label: { type: String, trim: true },
            price: { type: Number, min: 0 }
        }],
    cuisinier: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    ingredients: [{
            type: String,
            trim: true
        }],
    available: {
        type: Boolean,
        default: true
    },
    stock: {
        type: Number,
        default: 0,
        min: [0, "Le stock ne peut pas être négatif"]
    },
    promoActive: {
        type: Boolean,
        default: false,
    },
    promoPercent: {
        type: Number,
        min: [0, 'La remise ne peut pas être négative'],
        max: [90, 'La remise ne peut pas dépasser 90%'],
        default: 0,
    },
    promoStart: { type: Date },
    promoEnd: { type: Date },
    preparationTime: {
        type: Number,
        required: [true, "Le temps de préparation est obligatoire"],
        min: [5, "Le temps minimum est de 5 minutes"]
    },
    rating: {
        type: Number,
        default: 0,
        min: [0, "La note minimale est 0"],
        max: [5, "La note maximale est 5"]
    },
    ratingCount: {
        type: Number,
        default: 0,
        min: 0
    }
}, {
    timestamps: true
});
platSchema.index({ cuisinier: 1, available: 1 });
platSchema.index({ category: 1 });
platSchema.index({ rating: -1 });
export const Plat = mongoose.model("Plat", platSchema);
//# sourceMappingURL=plat_model.js.map