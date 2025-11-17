import jwt from "jsonwebtoken";
import { User } from "../models/users_model.js";
export const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({
                success: false,
                message: 'Token manquant ou invalide'
            });
            return;
        }
        const token = authHeader.substring(7); // Remove 'Bearer ' prefix
        if (!token) {
            res.status(401).json({
                success: false,
                message: 'Token manquant'
            });
            return;
        }
        // Vérifier le token
        const secret = process.env.JWT_SECRET;
        if (!secret) {
            res.status(500).json({
                success: false,
                message: 'Configuration serveur invalide'
            });
            return;
        }
        const decoded = jwt.verify(token, secret);
        // Vérifier que l'utilisateur existe toujours
        const user = await User.findById(decoded.userId);
        if (!user || !user.isActive) {
            res.status(401).json({
                success: false,
                message: 'Utilisateur non trouvé ou compte désactivé'
            });
            return;
        }
        // Ajouter les infos utilisateur à la requête
        req.user = decoded;
        next();
    }
    catch (error) {
        console.error('Erreur d\'authentification:', error);
        if (error.name === 'JsonWebTokenError') {
            res.status(401).json({
                success: false,
                message: 'Token invalide'
            });
            return;
        }
        if (error.name === 'TokenExpiredError') {
            res.status(401).json({
                success: false,
                message: 'Token expiré'
            });
            return;
        }
        res.status(500).json({
            success: false,
            message: 'Erreur serveur lors de l\'authentification'
        });
    }
};
export const authorize = (...roles) => {
    return (req, res, next) => {
        const user = req.user;
        if (!user) {
            res.status(401).json({
                success: false,
                message: 'Utilisateur non authentifié'
            });
            return;
        }
        if (!roles.includes(user.role)) {
            res.status(403).json({
                success: false,
                message: 'Accès non autorisé pour ce rôle'
            });
            return;
        }
        next();
    };
};
//# sourceMappingURL=auth.js.map