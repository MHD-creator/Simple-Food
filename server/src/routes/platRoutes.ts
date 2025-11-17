import { Router } from "express";
import { 
  createPlat, 
  getPlats, 
  getPlatById, 
  updatePlat, 
  deletePlat, 
  getMyPlats,
  platValidation 
} from "../controllers/platController.js";
import { authenticate, authorize } from "../middleware/auth.js";

const router = Router();

/**
 * @route   POST /api/plats
 * @desc    Créer un nouveau plat (cuisinier uniquement)
 * @access  Private (cuisinier)
 */
router.post('/', authenticate, authorize('cuisinier'), platValidation, createPlat);

/**
 * @route   GET /api/plats
 * @desc    Récupérer tous les plats (avec filtres)
 * @access  Public
 */
router.get('/', getPlats);

/**
 * @route   GET /api/plats/my
 * @desc    Récupérer les plats du cuisinier connecté
 * @access  Private (cuisinier)
 */
router.get('/my', authenticate, authorize('cuisinier'), getMyPlats);

/**
 * @route   GET /api/plats/:id
 * @desc    Récupérer un plat par son ID
 * @access  Public
 */
router.get('/:id', getPlatById);

/**
 * @route   PUT /api/plats/:id
 * @desc    Mettre à jour un plat (cuisinier uniquement)
 * @access  Private (cuisinier)
 */
router.put('/:id', authenticate, authorize('cuisinier'), platValidation, updatePlat);

/**
 * @route   DELETE /api/plats/:id
 * @desc    Supprimer un plat (cuisinier uniquement)
 * @access  Private (cuisinier)
 */
router.delete('/:id', authenticate, authorize('cuisinier'), deletePlat);

export default router;
