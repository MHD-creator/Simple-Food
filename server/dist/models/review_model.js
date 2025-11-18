import mongoose, { Document, Schema } from "mongoose";
const reviewSchema = new Schema({
    plat: { type: Schema.Types.ObjectId, ref: 'Plat', required: true, index: true },
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, trim: true, maxlength: 1000 },
}, { timestamps: true });
reviewSchema.index({ plat: 1, user: 1 }, { unique: true });
export const Review = mongoose.model('Review', reviewSchema);
//# sourceMappingURL=review_model.js.map