import { Router } from "express";
import { 
  createCommande, 
  getCommandes, 
  getCommandeById, 
  updateCommandeStatus,
  commandeValidation 
} from "../controllers/commandeController.js";
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
 * @desc    Récupérer les commandes (client ou cuisinier)
 * @access  Private (client, cuisinier)
 */
router.get('/', authenticate, authorize('client', 'cuisinier'), getCommandes);

/**
 * @route   GET /api/commandes/:id
 * @desc    Récupérer une commande par son ID
 * @access  Private (client, cuisinier)
 */
router.get('/:id', authenticate, authorize('client', 'cuisinier'), getCommandeById);

/**
 * @route   PUT /api/commandes/:id/status
 * @desc    Mettre à jour le statut d'une commande (cuisinier uniquement)
 * @access  Private (cuisinier)
 */
router.put('/:id/status', authenticate, authorize('cuisinier'), updateCommandeStatus);

export default router;
