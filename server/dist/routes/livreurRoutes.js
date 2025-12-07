import { Router } from "express";
import { authenticate, authorize } from "../middleware/auth.js";
import { createLivreur, getLivreurs, updateLivreur, deleteLivreur, livreurValidation, } from "../controllers/livreurController.js";
const router = Router();
// Toutes les routes livreur sont réservées aux cuisiniers
router.use(authenticate, authorize('cuisinier'));
/**
 * @route   POST /api/livreurs
 * @desc    Créer un nouveau livreur
 * @access  Private (cuisinier)
 */
router.post('/', livreurValidation, createLivreur);
/**
 * @route   GET /api/livreurs
 * @desc    Lister les livreurs du cuisinier connecté
 * @access  Private (cuisinier)
 */
router.get('/', getLivreurs);
/**
 * @route   PUT /api/livreurs/:id
 * @desc    Mettre à jour un livreur (nom, téléphone, mot de passe)
 * @access  Private (cuisinier)
 */
router.put('/:id', livreurValidation, updateLivreur);
/**
 * @route   DELETE /api/livreurs/:id
 * @desc    Désactiver un livreur
 * @access  Private (cuisinier)
 */
router.delete('/:id', deleteLivreur);
export default router;
//# sourceMappingURL=livreurRoutes.js.map