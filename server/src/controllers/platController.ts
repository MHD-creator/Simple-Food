import type { Request, Response } from "express";
import { body, validationResult } from "express-validator";
import type { IPlat } from "../models/plat_model.js";
import { Plat } from "../models/plat_model.js";
import type { AuthRequest } from "../middleware/auth.js";

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

    const { name, description, price, category, ingredients, preparationTime } = req.body;
    const cuisinierId = (req as AuthRequest).user.userId;

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

  } catch (error: any) {
    console.error('Erreur lors de la création du plat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la création du plat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
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

    const updatedPlat = await Plat.findByIdAndUpdate(
      id,
      { ...req.body },
      { new: true, runValidators: true }
    ).populate('cuisinier', 'name telephone');

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
