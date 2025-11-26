import type { Request, Response } from "express";
import { body, validationResult } from "express-validator";
import jwt from "jsonwebtoken";
import type { SignOptions } from "jsonwebtoken";
import type { IUser } from "../models/users_model.js";
import { User } from "../models/users_model.js";

interface JwtPayload {
  userId: string;
  telephone: string;
  role: string;
}

const normalizePhone = (input: string): string => input ? input.replace(/\D/g, '') : '';

const generateToken = (user: IUser): string => {
  const payload: JwtPayload = {
    userId: (user._id as any).toString(),
    telephone: user.telephone,
    role: user.role
  };

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is not defined');
  }
  
  return jwt.sign(payload, secret, { expiresIn: '7d' });
};

export const changePasswordValidation = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Le mot de passe actuel est requis'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('Le nouveau mot de passe doit contenir au moins 6 caractères'),
  body('confirmNewPassword')
    .custom((value, { req }) => value === req.body.newPassword)
    .withMessage('La confirmation ne correspond pas au nouveau mot de passe'),
];

export const changePassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ success: false, message: 'Erreurs de validation', errors: errors.array() });
      return;
    }

    const userId = (req as any).user.userId;
    const { currentPassword, newPassword } = req.body as { currentPassword: string; newPassword: string };

    const user = await User.findById(userId).select('+password');
    if (!user) {
      res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
      return;
    }

    const ok = await user.comparePassword(currentPassword);
    if (!ok) {
      res.status(400).json({ success: false, message: 'Mot de passe actuel incorrect' });
      return;
    }

    user.password = newPassword;
    await user.save();

    res.status(200).json({ success: true, message: 'Mot de passe mis à jour' });
  } catch (error) {
    console.error('Erreur lors du changement de mot de passe:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    const { address } = req.body as { address?: string };

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
      return;
    }

    if (address !== undefined) {
      if (typeof address !== 'string' || address.trim().length === 0 || address.length > 300) {
        res.status(400).json({ success: false, message: 'Adresse invalide' });
        return;
      }
      user.address = address.trim();
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Profil mis à jour',
      data: {
        id: user._id,
        name: user.name,
        telephone: user.telephone,
        role: user.role,
        age: user.age,
        email: user.email,
        address: user.address,
        profileImage: user.profileImage,
        isActive: user.isActive,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error: any) {
    console.error('Erreur lors de la mise à jour du profil:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

export const registerValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Le nom est obligatoire')
    .isLength({ max: 50 })
    .withMessage('Le nom ne peut pas dépasser 50 caractères'),
  
  body('telephone')
    .trim()
    .notEmpty()
    .withMessage('Le téléphone est obligatoire')
    .matches(/^\+?[0-9]{6,15}$/)
    .withMessage('Format de téléphone invalide'),
  
  body('password')
    .isLength({ min: 6 })
    .withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  
  body('role')
    .optional()
    .isIn(['client', 'cuisinier'])
    .withMessage('Le rôle doit être client ou cuisinier'),
  
  body('age')
    .optional()
    .isInt({ min: 13, max: 120 })
    .withMessage('L\'âge doit être entre 13 et 120 ans'),
  
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email invalide')
    .normalizeEmail()
];

export const loginValidation = [
  body('telephone')
    .trim()
    .notEmpty()
    .withMessage('Le téléphone est obligatoire'),
  
  body('password')
    .notEmpty()
    .withMessage('Le mot de passe est obligatoire')
];

export const register = async (req: Request, res: Response): Promise<void> => {
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

    const { name, telephone: telInput, password, role = 'client', age, email, address } = req.body;
    const telephone = normalizePhone(telInput);

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await User.findOne({ telephone });
    if (existingUser) {
      res.status(400).json({
        success: false,
        message: 'Ce numéro de téléphone est déjà utilisé'
      });
      return;
    }

    // Créer le nouvel utilisateur
    const user = new User({
      name,
      telephone,
      password,
      role,
      age,
      email,
      address
    });

    await user.save();

    // Générer le token
    const token = generateToken(user);

    // Retourner les infos utilisateur (sans le mot de passe)
    const userResponse = {
      id: user._id,
      name: user.name,
      telephone: user.telephone,
      role: user.role,
      age: user.age,
      email: user.email,
      address: user.address,
      profileImage: user.profileImage,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };

    res.status(201).json({
      success: true,
      message: 'Inscription réussie',
      data: {
        user: userResponse,
        token
      }
    });

  } catch (error: any) {
    console.error('Erreur lors de l\'inscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de l\'inscription',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
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

    const { telephone: telInput, password } = req.body;
    const telephone = normalizePhone(telInput);

    // Trouver l'utilisateur avec le mot de passe
    const user = await User.findOne({ telephone }).select('+password');
    if (!user) {
      res.status(401).json({
        success: false,
        message: 'Téléphone ou mot de passe incorrect'
      });
      return;
    }

    // Vérifier si le compte est actif
    if (!user.isActive) {
      res.status(401).json({
        success: false,
        message: 'Votre compte a été désactivé'
      });
      return;
    }

    // Vérifier le mot de passe
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      res.status(401).json({
        success: false,
        message: 'Téléphone ou mot de passe incorrect'
      });
      return;
    }

    // Générer le token
    const token = generateToken(user);

    // Retourner les infos utilisateur (sans le mot de passe)
    const userResponse = {
      id: user._id,
      name: user.name,
      telephone: user.telephone,
      role: user.role,
      age: user.age,
      email: user.email,
      address: user.address,
      profileImage: user.profileImage,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };

    res.status(200).json({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: userResponse,
        token
      }
    });

  } catch (error: any) {
    console.error('Erreur lors de la connexion:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la connexion',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const getProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).user.userId;
    
    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
      return;
    }

    const userResponse = {
      id: user._id,
      name: user.name,
      telephone: user.telephone,
      role: user.role,
      age: user.age,
      email: user.email,
      address: user.address,
      profileImage: user.profileImage,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };

    res.status(200).json({
      success: true,
      data: userResponse
    });

  } catch (error: any) {
    console.error('Erreur lors de la récupération du profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
