import { Router } from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
const router = Router();
// Ensure uploads directory exists
const uploadsDir = path.join(process.cwd(), 'server', 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}
// Multer storage configuration
const storage = multer.diskStorage({
    destination: function (_req, _file, cb) {
        cb(null, uploadsDir);
    },
    filename: function (_req, file, cb) {
        const ext = path.extname(file.originalname || '');
        const base = path.basename(file.originalname || 'file', ext).replace(/[^a-zA-Z0-9_-]/g, '');
        const name = `${base || 'image'}-${Date.now()}${ext || ''}`;
        cb(null, name);
    },
});
const upload = multer({ storage });
/**
 * POST /api/uploads
 * Champs acceptés:
 *  - image: fichier (single)
 * Réponse:
 *  - { success: true, data: { url: '/uploads/<filename>' } }
 */
router.post('/', upload.single('image'), (req, res) => {
    // Multer a placé le fichier dans req.file
    // En cas d'erreur, multer déclenchera l'error handler d'Express
    const file = req.file;
    if (!file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier reçu' });
    }
    const url = `/uploads/${file.filename}`;
    return res.status(201).json({ success: true, data: { url } });
});
export default router;
//# sourceMappingURL=uploadRoutes.js.map