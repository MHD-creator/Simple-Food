import type { Request, Response } from "express";
import { body, validationResult } from "express-validator";
import type { IPlat } from "../models/plat_model.js";
import { Plat } from "../models/plat_model.js";
import { Review } from "../models/review_model.js";
import type { AuthRequest } from "../middleware/auth.js";
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
  ,
  body('stock')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Le stock doit être un entier >= 0')
  ,
  body('promoActive')
    .optional()
    .isBoolean()
    .withMessage('promoActive doit être un booléen')
  ,
  body('promoPercent')
    .optional()
    .isFloat({ min: 0, max: 90 })
    .withMessage('promoPercent doit être entre 0 et 90')
  ,
  body('promoStart')
    .optional()
    .isISO8601()
    .withMessage('promoStart doit être une date ISO')
  ,
  body('promoEnd')
    .optional()
    .isISO8601()
    .withMessage('promoEnd doit être une date ISO')
];

export const createPlat = async (req: Request, res: Response): Promise<void> => {
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

    const { name, description, price, category, ingredients, preparationTime, stock, promoActive, promoPercent, promoStart, promoEnd } = req.body as any;
    const images = Array.isArray((req.body as any).images)
      ? ((req.body as any).images as any[]).filter((u) => typeof u === 'string' && u.length > 0)
      : [];
    const prices: { label: string; price: number }[] = Array.isArray((req.body as any).prices)
      ? ((req.body as any).prices as any[])
          .map((p) => ({
            label:
              typeof p?.label === 'string'
                ? p.label
                : ((p as any)?.libelle || (p as any)?.label || '')?.toString() ?? '',
            price:
              typeof p?.price === 'number'
                ? p.price
                : Number((p as any)?.prix ?? (p as any)?.price ?? 0),
          }))
          .filter((p) => p.label && !Number.isNaN(p.price) && p.price >= 0)
      : [];
    const cuisinierId = (req as AuthRequest).user.userId;

    const cover = (req.body as any).image || (images.length > 0 ? images[0] : null);
    const firstPrice = prices[0]?.price ?? 0;
    const basePrice = typeof price === 'number' ? price : firstPrice;

    const plat = new Plat({
      name,
      description,
      price: basePrice,
      category,
      ingredients,
      preparationTime,
      cuisinier: cuisinierId,
      image: cover,
      images: images,
      prices: prices,
      ...(typeof stock === 'number' ? { stock } : {}),
      ...(typeof promoActive === 'boolean' ? { promoActive } : {}),
      ...(typeof promoPercent === 'number' ? { promoPercent } : {}),
      ...(promoStart ? { promoStart: new Date(promoStart) } : {}),
      ...(promoEnd ? { promoEnd: new Date(promoEnd) } : {})
    });

    await plat.save();

    // Populer les infos du cuisinier (y compris localisation cuisine et frais de livraison)
    await plat.populate('cuisinier', 'name telephone address kitchenLat kitchenLng deliveryBaseFee deliveryFeePerKm');

    res.status(201).json({
      success: true,
      message: 'Plat créé avec succès',
      data: plat
    });

  } catch (error: any) {
    console.error('Erreur lors de la création du plat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la création du plat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const createOrUpdateReview = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params; // plat id
    const { rating, comment } = req.body as { rating: number; comment?: string };
    const userId = (req as AuthRequest).user.userId;

    const plat = await Plat.findById(id);
    if (!plat) {
      res.status(404).json({ success: false, message: 'Plat non trouvé' });
      return;
    }

    if (typeof rating !== 'number' || rating < 1 || rating > 5) {
      res.status(400).json({ success: false, message: 'La note doit être entre 1 et 5' });
      return;
    }

    await Review.findOneAndUpdate(
      { plat: id, user: userId },
      { $set: { rating, comment } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

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
  } catch (error: any) {
    console.error('Erreur lors de la création/mise à jour de l\'avis:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de l\'enregistrement de l\'avis' });
  }
};

export const getReviewsForPlat = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params; // plat id
    const { page = 1, limit = 10 } = req.query;
    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
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
  } catch (error: any) {
    console.error('Erreur lors de la récupération des avis:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération des avis' });
  }
};

export const getPlats = async (req: Request, res: Response): Promise<void> => {
  try {
    const { category, available, cuisinier, page = 1, limit = 10, q } = req.query;
    
    const filter: any = {};
    
    if (category) filter.category = category;
    if (available !== undefined) filter.available = available === 'true';
    if (cuisinier) filter.cuisinier = cuisinier;
    if (q && typeof q === 'string' && q.trim().length > 0) {
      const regex = new RegExp(q.trim(), 'i');
      filter.$or = [
        { name: regex },
        { description: regex },
        { category: regex },
      ];
    }

    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    const skip = (pageNum - 1) * limitNum;

    const plats = await Plat.find(filter)
      .populate('cuisinier', 'name telephone address kitchenLat kitchenLng deliveryBaseFee deliveryFeePerKm')
      .sort({ promoActive: -1, createdAt: -1 })
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

  } catch (error: any) {
    console.error('Erreur lors de la récupération des plats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des plats',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const getPlatById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const plat = await Plat.findById(id)
      .populate('cuisinier', 'name telephone address kitchenLat kitchenLng deliveryBaseFee deliveryFeePerKm');

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

  } catch (error: any) {
    console.error('Erreur lors de la récupération du plat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération du plat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const updatePlat = async (req: Request, res: Response): Promise<void> => {
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
    const cuisinierId = (req as AuthRequest).user.userId;

    const plat = await Plat.findOne({ _id: id, cuisinier: cuisinierId });
    
    if (!plat) {
      res.status(404).json({
        success: false,
        message: 'Plat non trouvé ou non autorisé'
      });
      return;
    }

    const body: any = { ...req.body };
    if (Array.isArray(body.images)) {
      body.images = body.images.filter((u: any) => typeof u === 'string' && u.length > 0);
      if (!body.image && body.images.length > 0) {
        body.image = body.images[0];
      }
    }

    const updatedPlat = await Plat.findByIdAndUpdate(
      id,
      body,
      { new: true, runValidators: true }
    ).populate('cuisinier', 'name telephone address kitchenLat kitchenLng deliveryBaseFee deliveryFeePerKm');

    res.status(200).json({
      success: true,
      message: 'Plat mis à jour avec succès',
      data: updatedPlat
    });

  } catch (error: any) {
    console.error('Erreur lors de la mise à jour du plat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour du plat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const deletePlat = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const cuisinierId = (req as AuthRequest).user.userId;

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

  } catch (error: any) {
    console.error('Erreur lors de la suppression du plat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la suppression du plat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const getMyPlats = async (req: Request, res: Response): Promise<void> => {
  try {
    const cuisinierId = (req as AuthRequest).user.userId;
    const { page = 1, limit = 10 } = req.query;

    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
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

  } catch (error: any) {
    console.error('Erreur lors de la récupération de mes plats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des plats',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
