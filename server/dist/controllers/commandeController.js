import { body, validationResult } from "express-validator";
import { Commande } from "../models/commandes.js";
import { Plat } from "../models/plat_model.js";
export const commandeValidation = [
    body('plats')
        .isArray({ min: 1 })
        .withMessage('Au moins un plat est requis'),
    body('plats.*.plat')
        .isMongoId()
        .withMessage('ID de plat invalide'),
    body('plats.*.quantity')
        .isInt({ min: 1 })
        .withMessage('La quantité doit être au moins 1'),
    body('deliveryAddress')
        .trim()
        .notEmpty()
        .withMessage('L\'adresse de livraison est obligatoire')
        .isLength({ max: 300 })
        .withMessage('L\'adresse ne peut pas dépasser 300 caractères'),
    body('deliveryPhone')
        .trim()
        .notEmpty()
        .withMessage('Le téléphone de livraison est obligatoire')
        .matches(/^\+?[0-9]{6,15}$/)
        .withMessage('Format de téléphone invalide'),
    body('notes')
        .optional()
        .isLength({ max: 500 })
        .withMessage('Les notes ne peuvent pas dépasser 500 caractères')
];
export const createCommande = async (req, res) => {
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
        const { plats, deliveryAddress, deliveryPhone, notes } = req.body;
        const clientId = req.user.userId;
        // Vérifier que tous les plats existent et sont disponibles
        const platIds = plats.map((p) => p.plat);
        const platsFound = await Plat.find({ _id: { $in: platIds }, available: true });
        if (platsFound.length !== platIds.length) {
            res.status(400).json({
                success: false,
                message: 'Un ou plusieurs plats ne sont pas disponibles'
            });
            return;
        }
        // Calculer le montant total
        let totalAmount = 0;
        const commandePlats = plats.map((p) => {
            const plat = platsFound.find((pl) => pl._id.toString() === p.plat);
            if (!plat) {
                throw new Error('Plat non trouvé');
            }
            const subtotal = plat.price * p.quantity;
            totalAmount += subtotal;
            return {
                plat: p.plat,
                quantity: p.quantity,
                price: plat.price
            };
        });
        // Vérifier que tous les plats sont du même cuisinier
        const cuisiniers = new Set(platsFound.map(p => p.cuisinier.toString()));
        if (cuisiniers.size > 1) {
            res.status(400).json({
                success: false,
                message: 'Tous les plats doivent provenir du même cuisinier'
            });
            return;
        }
        const cuisinierId = platsFound[0]?.cuisinier;
        // Calculer le temps de livraison estimé (30 min + temps de préparation max)
        const maxPrepTime = Math.max(...platsFound.map(p => p.preparationTime || 0));
        const estimatedDeliveryTime = new Date();
        estimatedDeliveryTime.setMinutes(estimatedDeliveryTime.getMinutes() + 30 + maxPrepTime);
        const commande = new Commande({
            client: clientId,
            plats: commandePlats,
            totalAmount,
            deliveryAddress,
            deliveryPhone,
            notes,
            cuisinier: cuisinierId,
            estimatedDeliveryTime
        });
        await commande.save();
        // Populer les informations
        await commande.populate([
            { path: 'client', select: 'name telephone' },
            { path: 'cuisinier', select: 'name telephone address' },
            { path: 'plats.plat', select: 'name price image' }
        ]);
        res.status(201).json({
            success: true,
            message: 'Commande créée avec succès',
            data: commande
        });
    }
    catch (error) {
        console.error('Erreur lors de la création de la commande:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la création de la commande',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const getCommandes = async (req, res) => {
    try {
        const { status, page = 1, limit = 10 } = req.query;
        const userId = req.user.userId;
        const userRole = req.user.role;
        const filter = {};
        // Filtrer selon le rôle
        if (userRole === 'client') {
            filter.client = userId;
        }
        else if (userRole === 'cuisinier') {
            filter.cuisinier = userId;
        }
        if (status)
            filter.status = status;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;
        const commandes = await Commande.find(filter)
            .populate('client', 'name telephone')
            .populate('cuisinier', 'name telephone address')
            .populate('plats.plat', 'name price image')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum);
        const total = await Commande.countDocuments(filter);
        res.status(200).json({
            success: true,
            data: commandes,
            pagination: {
                page: pageNum,
                limit: limitNum,
                total,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération des commandes:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la récupération des commandes',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const getCommandeById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;
        const commande = await Commande.findById(id)
            .populate('client', 'name telephone')
            .populate('cuisinier', 'name telephone address')
            .populate('plats.plat', 'name price image description');
        if (!commande) {
            res.status(404).json({
                success: false,
                message: 'Commande non trouvée'
            });
            return;
        }
        // Vérifier les autorisations
        if (userRole === 'client' && commande.client._id.toString() !== userId) {
            res.status(403).json({
                success: false,
                message: 'Accès non autorisé'
            });
            return;
        }
        if (userRole === 'cuisinier' && commande.cuisinier._id.toString() !== userId) {
            res.status(403).json({
                success: false,
                message: 'Accès non autorisé'
            });
            return;
        }
        res.status(200).json({
            success: true,
            data: commande
        });
    }
    catch (error) {
        console.error('Erreur lors de la récupération de la commande:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la récupération de la commande',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const updateCommandeStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const userId = req.user.userId;
        const userRole = req.user.role;
        // Seuls les cuisiniers peuvent modifier le statut
        if (userRole !== 'cuisinier') {
            res.status(403).json({
                success: false,
                message: 'Seuls les cuisiniers peuvent modifier le statut des commandes'
            });
            return;
        }
        const validStatuses = ['en_attente', 'en_preparation', 'en_livraison', 'livrée', 'annulée'];
        if (!validStatuses.includes(status)) {
            res.status(400).json({
                success: false,
                message: 'Statut invalide'
            });
            return;
        }
        const commande = await Commande.findOne({ _id: id, cuisinier: userId });
        if (!commande) {
            res.status(404).json({
                success: false,
                message: 'Commande non trouvée ou non autorisée'
            });
            return;
        }
        // Mettre à jour le statut et éventuellement la date de livraison
        const updateData = { status };
        if (status === 'livrée') {
            updateData.actualDeliveryTime = new Date();
        }
        const updatedCommande = await Commande.findByIdAndUpdate(id, updateData, { new: true }).populate([
            { path: 'client', select: 'name telephone' },
            { path: 'cuisinier', select: 'name telephone address' },
            { path: 'plats.plat', select: 'name price image' }
        ]);
        res.status(200).json({
            success: true,
            message: 'Statut de la commande mis à jour avec succès',
            data: updatedCommande
        });
    }
    catch (error) {
        console.error('Erreur lors de la mise à jour du statut:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de la mise à jour du statut',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};
export const cancelCommandeByClient = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const commande = await Commande.findById(id);
        if (!commande) {
            res.status(404).json({ success: false, message: 'Commande non trouvée' });
            return;
        }
        if (commande.client.toString() !== userId) {
            res.status(403).json({ success: false, message: 'Accès non autorisé' });
            return;
        }
        if (commande.status !== 'en_attente') {
            res.status(400).json({ success: false, message: 'Seules les commandes en attente peuvent être annulées' });
            return;
        }
        commande.status = 'annulée';
        await commande.save();
        await commande.populate([
            { path: 'client', select: 'name telephone' },
            { path: 'cuisinier', select: 'name telephone address' },
            { path: 'plats.plat', select: 'name price image' }
        ]);
        res.status(200).json({ success: true, message: 'Commande annulée', data: commande });
    }
    catch (error) {
        console.error('Erreur lors de l\'annulation de la commande:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de l\'annulation' });
    }
};
//# sourceMappingURL=commandeController.js.map