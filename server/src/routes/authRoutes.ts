import { Router } from "express";
import { register, login, getProfile, registerValidation, loginValidation, changePassword, changePasswordValidation } from "../controllers/authController.js";
import { authenticate } from "../middleware/auth.js";

const router = Router();

/**
 * @route   POST /api/auth/register
 * @desc    Inscription d'un nouvel utilisateur
 * @access  Public
 */
router.post('/register', registerValidation, register);

/**
 * @route   POST /api/auth/login
 * @desc    Connexion d'un utilisateur
 * @access  Public
 */
router.post('/login', loginValidation, login);

/**
 * @route   GET /api/auth/profile
 * @desc    Récupérer le profil de l'utilisateur connecté
 * @access  Private
 */
router.get('/profile', authenticate, getProfile);

/**
 * @route   PUT /api/auth/change-password
 * @desc    Changer le mot de passe de l'utilisateur connecté
 * @access  Private
 */
router.put('/change-password', authenticate, changePasswordValidation, changePassword);

export default router;
