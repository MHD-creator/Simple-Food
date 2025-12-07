import { body, validationResult } from "express-validator";
import { User } from "../models/users_model.js";
const normalizePhone = (input) => (input ? input.replace(/\D/g, '') : '');
export const livreurValidation = [
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
        .optional()
        .isLength({ min: 6 })
        .withMessage('Le mot de passe doit contenir au moins 6 caractères'),
];
export const createLivreur = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({ success: false, message: 'Erreurs de validation', errors: errors.array() });
            return;
        }
        const cuisinierId = req.user.userId;
        const { name, telephone: telInput, password } = req.body;
        const telephone = normalizePhone(telInput);
        const existing = await User.findOne({ telephone });
        if (existing) {
            res.status(400).json({ success: false, message: 'Ce numéro de téléphone est déjà utilisé' });
            return;
        }
        const livreur = new User({
            name,
            telephone,
            password,
            role: 'livreur',
            cuisinier: cuisinierId,
        });
        await livreur.save();
        res.status(201).json({
            success: true,
            message: 'Livreur créé avec succès',
            data: {
                id: livreur._id,
                name: livreur.name,
                telephone: livreur.telephone,
                role: livreur.role,
                cuisinier: livreur.cuisinier,
                isActive: livreur.isActive,
                createdAt: livreur.createdAt,
                updatedAt: livreur.updatedAt,
            },
        });
    }
    catch (error) {
        console.error('Erreur lors de la création du livreur:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de la création du livreur' });
    }
};
export const getLivreurs = async (req, res) => {
    try {
        const cuisinierId = req.user.userId;
        const livreurs = await User.find({ role: 'livreur', cuisinier: cuisinierId }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: livreurs });
    }
    catch (error) {
        console.error('Erreur lors de la récupération des livreurs:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération des livreurs' });
    }
};
export const updateLivreur = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({ success: false, message: 'Erreurs de validation', errors: errors.array() });
            return;
        }
        const cuisinierId = req.user.userId;
        const { id } = req.params;
        const { name, telephone: telInput, password } = req.body;
        const livreur = await User.findOne({ _id: id, role: 'livreur', cuisinier: cuisinierId }).select('+password');
        if (!livreur) {
            res.status(404).json({ success: false, message: 'Livreur non trouvé' });
            return;
        }
        if (name !== undefined)
            livreur.name = name;
        if (telInput !== undefined) {
            const telephone = normalizePhone(telInput);
            if (telephone !== livreur.telephone) {
                const exists = await User.findOne({ telephone });
                if (exists && String(exists._id) !== String(livreur._id)) {
                    res.status(400).json({ success: false, message: 'Ce numéro de téléphone est déjà utilisé' });
                    return;
                }
                livreur.telephone = telephone;
            }
        }
        if (password !== undefined && password.trim().length >= 6) {
            livreur.password = password;
        }
        await livreur.save();
        res.status(200).json({
            success: true,
            message: 'Livreur mis à jour',
            data: {
                id: livreur._id,
                name: livreur.name,
                telephone: livreur.telephone,
                role: livreur.role,
                cuisinier: livreur.cuisinier,
                isActive: livreur.isActive,
                createdAt: livreur.createdAt,
                updatedAt: livreur.updatedAt,
            },
        });
    }
    catch (error) {
        console.error('Erreur lors de la mise à jour du livreur:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de la mise à jour du livreur' });
    }
};
export const deleteLivreur = async (req, res) => {
    try {
        const cuisinierId = req.user.userId;
        const { id } = req.params;
        const livreur = await User.findOne({ _id: id, role: 'livreur', cuisinier: cuisinierId });
        if (!livreur) {
            res.status(404).json({ success: false, message: 'Livreur non trouvé' });
            return;
        }
        // Suppression logique : désactiver le compte
        livreur.isActive = false;
        await livreur.save();
        res.status(200).json({ success: true, message: 'Livreur désactivé' });
    }
    catch (error) {
        console.error('Erreur lors de la suppression du livreur:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur lors de la suppression du livreur' });
    }
};
//# sourceMappingURL=livreurController.js.map