import { initDb } from "./db/db_init.js";
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import path from "path";
import authRoutes from "./routes/authRoutes.js";
import platRoutes from "./routes/platRoutes.js";
import commandeRoutes from "./routes/commandeRoutes.js";
import uploadRoutes from "./routes/uploadRoutes.js";
// Charger les variables d'environnement
dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;
// Initialiser la base de données
initDb();
// Middlewares
const allowedOrigins = [
    process.env.FRONTEND_URL,
    'http://localhost:3000',
    'http://127.0.0.1:3000',
].filter(Boolean);
app.use(cors({
    origin: (origin, callback) => {
        if (!origin)
            return callback(null, true);
        const isLocalhostDynamic = /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin);
        if (allowedOrigins.includes(origin) || isLocalhostDynamic) {
            return callback(null, true);
        }
        return callback(new Error('Not allowed by CORS'));
    },
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
// Routes
app.use('/api/auth', authRoutes);
app.use('/api/plats', platRoutes);
app.use('/api/commandes', commandeRoutes);
app.use('/api/uploads', uploadRoutes);
// Fichiers statiques (images uploadées)
app.use('/uploads', express.static(path.join(process.cwd(), 'server', 'uploads')));
// Route de test
app.get('/api/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Serveur Simple Food opérationnel',
        timestamp: new Date().toISOString()
    });
});
// Gestion des erreurs 404
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée'
    });
});
// Gestion des erreurs globales
app.use((err, req, res, next) => {
    console.error('Erreur globale:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Erreur serveur interne',
        error: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});
// Démarrer le serveur
app.listen(PORT, () => {
    console.log(`🚀 Serveur Simple Food démarré sur le port ${PORT}`);
    console.log(`📱 Environnement: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 API disponible sur: http://localhost:${PORT}/api`);
});
export default app;
//# sourceMappingURL=app.js.map