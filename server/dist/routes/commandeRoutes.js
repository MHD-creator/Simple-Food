import { Router } from "express";
import { createCommande, getCommandes, getCommandeById, updateCommandeStatus, commandeValidation, cancelCommandeByClient } from "../controllers/commandeController.js";
import { authenticate, authorize } from "../middleware/auth.js";
const router = Router();
/**
 * @route   POST /api/commandes
 * @desc    Créer une nouvelle commande (client uniquement)
 * @access  Private (client)
 */
router.post('/', authenticate, authorize('client'), commandeValidation, createCommande);
/**
 * @route   GET /api/commandes
 * @desc    Récupérer les commandes (client, cuisinier ou livreur)
 * @access  Private (client, cuisinier, livreur)
 */
router.get('/', authenticate, authorize('client', 'cuisinier', 'livreur'), getCommandes);
/**
 * @route   GET /api/commandes/:id
 * @desc    Récupérer une commande par son ID
 * @access  Private (client, cuisinier, livreur)
 */
router.get('/:id', authenticate, authorize('client', 'cuisinier', 'livreur'), getCommandeById);
/**
 * @route   PUT /api/commandes/:id/status
 * @desc    Mettre à jour le statut d'une commande (cuisinier ou livreur)
 * @access  Private (cuisinier, livreur)
 */
router.put('/:id/status', authenticate, authorize('cuisinier', 'livreur'), updateCommandeStatus);
/**
 * @route   PUT /api/commandes/:id/cancel
 * @desc    Annuler une commande (client uniquement, statut en_attente)
 * @access  Private (client)
 */
router.put('/:id/cancel', authenticate, authorize('client'), cancelCommandeByClient);
export default router;
//# sourceMappingURL=commandeRoutes.js.map