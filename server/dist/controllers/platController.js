import { body, validationResult } from "express-validator";
import { Plat } from "../models/plat_model.js";
import { Review } from "../models/review_model.js";
import mongoose from "mongoose";
export const platValidation = [
    body('name')
        .trim()
        .notEmpty()
        .withMessage('Le nom du plat est obligatoire')
        .isLength({ max: 100 })
        .withMessage('Le nom ne peut pas dépasser 100 caractères'),
    body('description')
        .trim()
        .notEmpty()
        .withMessage('La description est obligatoire')
        .isLength({ max: 500 })
        .withMessage('La description ne peut pas dépasser 500 caractères'),
    body('price')
        .isFloat({ min: 0 })
        .withMessage('Le prix doit être un nombre positif'),
    body('category')
        .isIn(['africain', 'européen', 'asiatique', 'fast-food', 'dessert', 'boisson'])
        .withMessage('Catégorie invalide'),
    body('ingredients')
        .isArray()
        .withMessage('Les ingrédients doivent être un tableau'),
    body('preparationTime')
        .isInt({ min: 5 })
        .withMessage('Le temps de préparation minimum est de 5 minutes')
];
export const createPlat = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({
                success: false,
                message: 'Erreurs de validation',
                errors: errors.array()
            });
            return;
        }
        const { name, description, price, category, ingredients, preparationTime } = req.body;
        const cuisinierId = req.user.userId;
        const plat = new Plat({
            name,
            description,
            price,
            category,
            ingredients,
            preparationTime,
            cuisinier: cuisinierId,
            image: req.body.image || null
        });
        await plat.save();
        // Populer les infos du cuisinier
        await plat.populate('cuisinier', 'name telephone');
        res.status(201).json({
            success: true,
            message: 'Plat créé avec succès',
            data: plat
        });
    }
    catch (error) {
        console.error('Erreur lors de la création du plat:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la création du plat',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const createOrUpdateReview = async (req, res) => {
    try {
        const { id } = req.params; // plat id
        const { rating, comment } = req.body;
        const userId = req.user.userId;
        const plat = await Plat.findById(id);
        if (!plat) {
            res.status(404).json({ success: false, message: 'Plat non trouvé' });
            return;
        }
        if (typeof rating !== 'number' || rating < 1 || rating > 5) {
            res.status(400).json({ success: false, message: 'La note doit être entre 1 et 5' });
            return;
        }
        await Review.findOneAndUpdate({ plat: id, user: userId }, { $set: { rating, comment } }, { upsert: true, new: true, setDefaultsOnInsert: true });
        const agg = await Review.aggregate([
            { $match: { plat: new mongoose.Types.ObjectId(id) } },
            { $group: { _id: '$plat', avg: { $avg: '$rating' }, count: { $sum: 1 } } }
        ]);
        const avg = agg[0]?.avg ?? 0;
        const count = agg[0]?.count ?? 0;
        plat.rating = Math.round(avg * 10) / 10; // round 1 decimal
        plat.ratingCount = count;
        await plat.save();
        res.status(200).json({ success: true, message: 'Avis enregistré', data: { rating: plat.rating, ratingCount: plat.ratingCount } });
    }
    catch (error) {
        console.error('Erreur lors de la création/mise à jour de l\'avis:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de l\'enregistrement de l\'avis' });
    }
};
export const getReviewsForPlat = async (req, res) => {
    try {
        const { id } = req.params; // plat id
        const { page = 1, limit = 10 } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;
        const plat = await Plat.findById(id);
        if (!plat) {
            res.status(404).json({ success: false, message: 'Plat non trouvé' });
            return;
        }
        const [items, total] = await Promise.all([
            Review.find({ plat: id })
                .populate('user', 'name telephone')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum),
            Review.countDocuments({ plat: id })
        ]);
        res.status(200).json({
            success: true,
            data: items,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération des avis' });
    }
};
export const getPlats = async (req, res) => {
    try {
        const { category, available, cuisinier, page = 1, limit = 10, q } = req.query;
        const filter = {};
        if (category)
            filter.category = category;
        if (available !== undefined)
            filter.available = available === 'true';
        if (cuisinier)
            filter.cuisinier = cuisinier;
        if (q && typeof q === 'string' && q.trim().length > 0) {
            const regex = new RegExp(q.trim(), 'i');
            filter.$or = [
                { name: regex },
                { description: regex },
                { category: regex },
            ];
        }
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;
        const plats = await Plat.find(filter)
            .populate('cuisinier', 'name telephone')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum);
        const total = await Plat.countDocuments(filter);
        res.status(200).json({
            success: true,
            data: plats,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération des plats:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la récupération des plats',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const getPlatById = async (req, res) => {
    try {
        const { id } = req.params;
        const plat = await Plat.findById(id)
            .populate('cuisinier', 'name telephone address');
        if (!plat) {
            res.status(404).json({
                success: false,
                message: 'Plat non trouvé'
            });
            return;
        }
        res.status(200).json({
            success: true,
            data: plat
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération du plat:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la récupération du plat',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const updatePlat = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({
                success: false,
                message: 'Erreurs de validation',
                errors: errors.array()
            });
            return;
        }
        const { id } = req.params;
        const cuisinierId = req.user.userId;
        const plat = await Plat.findOne({ _id: id, cuisinier: cuisinierId });
        if (!plat) {
            res.status(404).json({
                success: false,
                message: 'Plat non trouvé ou non autorisé'
            });
            return;
        }
        const updatedPlat = await Plat.findByIdAndUpdate(id, { ...req.body }, { new: true, runValidators: true }).populate('cuisinier', 'name telephone');
        res.status(200).json({
            success: true,
            message: 'Plat mis à jour avec succès',
            data: updatedPlat
        });
    }
    catch (error) {
        console.error('Erreur lors de la mise à jour du plat:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la mise à jour du plat',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const deletePlat = async (req, res) => {
    try {
        const { id } = req.params;
        const cuisinierId = req.user.userId;
        const plat = await Plat.findOne({ _id: id, cuisinier: cuisinierId });
        if (!plat) {
            res.status(404).json({
                success: false,
                message: 'Plat non trouvé ou non autorisé'
            });
            return;
        }
        await Plat.findByIdAndDelete(id);
        res.status(200).json({
            success: true,
            message: 'Plat supprimé avec succès'
        });
    }
    catch (error) {
        console.error('Erreur lors de la suppression du plat:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la suppression du plat',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const getMyPlats = async (req, res) => {
    try {
        const cuisinierId = req.user.userId;
        const { page = 1, limit = 10 } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;
        const plats = await Plat.find({ cuisinier: cuisinierId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum);
        const total = await Plat.countDocuments({ cuisinier: cuisinierId });
        res.status(200).json({
            success: true,
            data: plats,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération de mes plats:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la récupération des plats',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
//# sourceMappingURL=platController.js.map