import mongoose, { Document, Schema } from "mongoose";
import bcrypt from "bcryptjs";
const userSchema = new Schema({
    name: {
        type: String,
        required: [true, "Le nom est obligatoire"],
        trim: true,
        maxlength: [50, "Le nom ne peut pas dépasser 50 caractères"]
    },
    telephone: {
        type: String,
        required: [true, "Le téléphone est obligatoire"],
        unique: true,
        trim: true,
        match: [/^\+?[0-9]{6,15}$/, "Format de téléphone invalide"]
    },
    password: {
        type: String,
        required: [true, "Le mot de passe est obligatoire"],
        minlength: [6, "Le mot de passe doit contenir au moins 6 caractères"],
        select: false
    },
    role: {
        type: String,
        enum: ['client', 'cuisinier', 'livreur', 'admin'],
        default: 'client'
    },
    age: {
        type: Number,
        min: [13, "L'âge minimum est de 13 ans"],
        max: [120, "L'âge maximum est de 120 ans"]
    },
    email: {
        type: String,
        lowercase: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, "Email invalide"]
    },
    address: {
        type: String,
        maxlength: [200, "L'adresse ne peut pas dépasser 200 caractères"]
    },
    profileImage: {
        type: String
    },
    cuisinier: {
        type: Schema.Types.ObjectId,
        ref: "User",
    },
    kitchenLat: {
        type: Number,
    },
    kitchenLng: {
        type: Number,
    },
    deliveryBaseFee: {
        type: Number,
        default: 1000,
    },
    deliveryFeePerKm: {
        type: Number,
        default: 150,
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});
userSchema.pre("save", async function (next) {
    if (!this.isModified("password"))
        return next();
    try {
        const salt = await bcrypt.genSalt(12);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    }
    catch (error) {
        next(error);
    }
});
userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};
export const User = mongoose.model("User", userSchema);
//# sourceMappingURL=users_model.js.map