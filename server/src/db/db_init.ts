/*
    Initialisation de la base de données
*/
import mongoose from "mongoose";

async function initDb(): Promise<void> {
    try {
        const mongoUri = process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/simple_food";
        
        await mongoose.connect(mongoUri, {
            maxPoolSize: 10, // Nombre maximum de connexions
            serverSelectionTimeoutMS: 5000, // Timeout de sélection du serveur
            socketTimeoutMS: 45000, // Timeout du socket
        });
        
        console.log("✅ Base de données MongoDB connectée avec succès");
        console.log(`📍 URI: ${mongoUri}`);
        
        // Écouter les événements de connexion
        mongoose.connection.on('error', (error) => {
            console.error('❌ Erreur de connexion MongoDB:', error);
        });
        
        mongoose.connection.on('disconnected', () => {
            console.log('⚠️ Déconnecté de MongoDB');
        });
        
        mongoose.connection.on('reconnected', () => {
            console.log('🔄 Reconnecté à MongoDB');
        });
        
    } catch (error) {
        console.error("❌ Erreur lors de la connexion à la base de données:", error);
        process.exit(1);
    }
}

export { initDb };
