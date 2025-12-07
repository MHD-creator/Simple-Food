import type { Request, Response } from "express";
import { body, validationResult } from "express-validator";
import type { ICommande } from "../models/commandes.js";
import { Commande } from "../models/commandes.js";
import { Plat } from "../models/plat_model.js";
import { User } from "../models/users_model.js";
import type { AuthRequest } from "../middleware/auth.js";

const deg2rad = (deg: number): number => (deg * Math.PI) / 180;

const haversineKm = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number => {
  const R = 6371; // rayon de la Terre en km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) *
      Math.cos(deg2rad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

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
  body('deliveryLat')
    .optional()
    .isFloat()
    .withMessage('Latitude de livraison invalide'),
  body('deliveryLng')
    .optional()
    .isFloat()
    .withMessage('Longitude de livraison invalide'),
  
  body('notes')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Les notes ne peuvent pas dépasser 500 caractères')
];

export const createCommande = async (req: Request, res: Response): Promise<void> => {
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

    const { plats, deliveryAddress, deliveryPhone, notes, deliveryLat, deliveryLng } = req.body;
    const clientId = (req as AuthRequest).user.userId;

    // Vérifier que tous les plats existent et sont disponibles
    const platIds = plats.map((p: any) => p.plat);
    const platsFound = await Plat.find({ _id: { $in: platIds }, available: true });
    
    if (platsFound.length !== platIds.length) {
      res.status(400).json({
        success: false,
        message: 'Un ou plusieurs plats ne sont pas disponibles'
      });
      return;
    }

    // Vérifier le stock et calculer le total
    let totalAmount = 0;
    const insuffisants: Array<{ plat: string; requested: number; available: number }> = [];
    const commandePlats = plats.map((p: any) => {
      const plat = platsFound.find((pl: any) => pl._id.toString() === p.plat);
      if (!plat) {
        throw new Error('Plat non trouvé');
      }
      const requestedQty = Number(p.quantity) || 0;
      const availableQty = Number((plat as any).stock ?? 0);
      if (requestedQty < 1) {
        insuffisants.push({ plat: p.plat, requested: requestedQty, available: availableQty });
      }
      if (availableQty < requestedQty) {
        insuffisants.push({ plat: p.plat, requested: requestedQty, available: availableQty });
      }
      const subtotal = plat.price * requestedQty;
      totalAmount += subtotal;

      return {
        plat: p.plat,
        quantity: requestedQty,
        price: plat.price
      };
    });

    if (insuffisants.length > 0) {
      res.status(400).json({
        success: false,
        message: 'Stock insuffisant pour certains plats',
        details: insuffisants
      });
      return;
    }

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

    // Vérifier que le cuisinier a bien configuré la géolocalisation de sa cuisine
    const cuisinier = await User.findById(cuisinierId);
    if (!cuisinier || cuisinier.kitchenLat == null || cuisinier.kitchenLng == null) {
      res.status(400).json({
        success: false,
        message: "Le cuisinier n'a pas encore configuré la localisation de sa cuisine. La livraison n'est pas possible pour le moment."
      });
      return;
    }

    // Calculer les frais de livraison si la géolocalisation du client est disponible
    let deliveryFee = 0;
    if (
      typeof deliveryLat === 'number' &&
      typeof deliveryLng === 'number' &&
      typeof cuisinier.kitchenLat === 'number' &&
      typeof cuisinier.kitchenLng === 'number'
    ) {
      const distanceKm = haversineKm(
        cuisinier.kitchenLat,
        cuisinier.kitchenLng,
        deliveryLat,
        deliveryLng,
      );

      const baseFee = typeof (cuisinier as any).deliveryBaseFee === 'number'
        ? (cuisinier as any).deliveryBaseFee
        : 1000;
      const feePerKm = typeof (cuisinier as any).deliveryFeePerKm === 'number'
        ? (cuisinier as any).deliveryFeePerKm
        : 150;

      // Calcul simple : frais de base + tarif au km * distance
      const rawFee = baseFee + feePerKm * distanceKm;

      // Arrondir à l'entier supérieur pour éviter les décimales FCFA
      deliveryFee = Math.ceil(rawFee);
    }

    if (deliveryFee > 0) {
      totalAmount += deliveryFee;
    }

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
      estimatedDeliveryTime,
      deliveryLat,
      deliveryLng,
      deliveryFee,
    });

    await commande.save();

    // Décrémenter le stock des plats commandés et mettre à jour la disponibilité si nécessaire
    for (const item of commandePlats) {
      const platDoc = platsFound.find((pl: any) => pl._id.toString() === item.plat);
      if (!platDoc) continue;
      const newStock = Math.max(0, Number((platDoc as any).stock ?? 0) - Number(item.quantity));
      await Plat.findByIdAndUpdate(
        item.plat,
        {
          $set: { stock: newStock, available: newStock > 0 ? platDoc.available : false }
        },
        { new: false }
      );
    }

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

  } catch (error: any) {
    console.error('Erreur lors de la création de la commande:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la création de la commande',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const getCommandes = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const userId = (req as AuthRequest).user.userId;
    const userRole = (req as AuthRequest).user.role;

    const filter: any = {};
    
    // Filtrer selon le rôle
    if (userRole === 'client') {
      filter.client = userId;
    } else if (userRole === 'cuisinier') {
      filter.cuisinier = userId;
    } else if (userRole === 'livreur') {
      const livreur = await User.findById(userId);
      if (!livreur || !livreur.cuisinier) {
        res.status(403).json({
          success: false,
          message: "Aucun cuisinier associé au livreur."
        });
        return;
      }
      filter.cuisinier = livreur.cuisinier;
    }
    
    if (status) filter.status = status;

    const pageNum = parseInt(page as string);
    const limitNum = parseInt(limit as string);
    const skip = (pageNum - 1) * limitNum;

    const commandes = await Commande.find(filter)
      .populate('client', 'name telephone')
      .populate('cuisinier', 'name telephone address')
      .populate('livreur', 'name telephone')
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

  } catch (error: any) {
    console.error('Erreur lors de la récupération des commandes:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des commandes',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const getCommandeById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as AuthRequest).user.userId;
    const userRole = (req as AuthRequest).user.role;

    const commande = await Commande.findById(id)
      .populate('client', 'name telephone')
      .populate('cuisinier', 'name telephone address')
      .populate('livreur', 'name telephone')
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

    if (userRole === 'livreur') {
      const livreur = await User.findById(userId);
      if (!livreur || !livreur.cuisinier || commande.cuisinier._id.toString() !== (livreur.cuisinier as any).toString()) {
        res.status(403).json({
          success: false,
          message: 'Accès non autorisé'
        });
        return;
      }
    }

    res.status(200).json({
      success: true,
      data: commande
    });

  } catch (error: any) {
    console.error('Erreur lors de la récupération de la commande:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération de la commande',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const updateCommandeStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = (req as AuthRequest).user.userId;
    const userRole = (req as AuthRequest).user.role;

    const validStatuses = ['en_attente', 'en_preparation', 'en_livraison', 'livrée', 'annulée'];
    if (!validStatuses.includes(status)) {
      res.status(400).json({
        success: false,
        message: 'Statut invalide'
      });
      return;
    }

    let commande: ICommande | null = null;
    if (userRole === 'cuisinier') {
      commande = await Commande.findOne({ _id: id, cuisinier: userId });
    } else if (userRole === 'livreur') {
      const livreur = await User.findById(userId);
      if (!livreur || !livreur.cuisinier) {
        res.status(403).json({
          success: false,
          message: "Aucun cuisinier associé au livreur."
        });
        return;
      }
      // Le livreur ne peut manipuler que les commandes du cuisinier associé
      commande = await Commande.findOne({ _id: id, cuisinier: livreur.cuisinier });
      // Restreindre les statuts autorisés au livreur
      const livreurAllowed = ['en_livraison', 'livrée'];
      if (!livreurAllowed.includes(status)) {
        res.status(403).json({
          success: false,
          message: 'Le livreur ne peut modifier le statut que vers en_livraison ou livrée'
        });
        return;
      }
    } else {
      res.status(403).json({
        success: false,
        message: 'Rôle non autorisé pour la mise à jour du statut'
      });
      return;
    }
    
    if (!commande) {
      res.status(404).json({
        success: false,
        message: 'Commande non trouvée ou non autorisée'
      });
      return;
    }

    // Interdire de modifier une commande déjà annulée
    if (commande.status === 'annulée' && status !== 'annulée') {
      res.status(400).json({ success: false, message: 'Impossible de modifier une commande annulée' });
      return;
    }

    const previousStatus = commande.status;

    // Mettre à jour le statut et éventuellement la date de livraison
    const updateData: any = { status };
    if (status === 'livrée') {
      updateData.actualDeliveryTime = new Date();
    }

    const updatedCommande = await Commande.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).populate([
      { path: 'client', select: 'name telephone' },
      { path: 'cuisinier', select: 'name telephone address' },
      { path: 'plats.plat', select: 'name price image' }
    ]);

    // Si on vient d'annuler (et que ce n'était pas déjà annulé), alors restaurer le stock
    if (status === 'annulée' && previousStatus !== 'annulée') {
      try {
        for (const item of (commande.plats as any[])) {
          await Plat.findByIdAndUpdate(
            item.plat,
            {
              $inc: { stock: Number(item.quantity) },
              $set: { available: true },
            },
            { new: false }
          );
        }
      } catch (e) {
        console.error('Erreur lors de la restauration du stock:', e);
      }
    }

    res.status(200).json({
      success: true,
      message: 'Statut de la commande mis à jour avec succès',
      data: updatedCommande
    });

  } catch (error: any) {
    console.error('Erreur lors de la mise à jour du statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour du statut',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export const cancelCommandeByClient = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = (req as AuthRequest).user.userId;

    const commande = await Commande.findById(id);
    if (!commande) {
      res.status(404).json({ success: false, message: 'Commande non trouvée' });
      return;
    }
    if (commande.client.toString() !== userId) {
      res.status(403).json({ success: false, message: 'Accès non autorisé' });
      return;
    }
    // Utiliser une variable locale pour éviter un narrowing contradictoire
    const st: string = (commande.status as any) as string;
    // Si déjà annulée, ne pas retraiter
    if (st === 'annulée') {
      await commande.populate([
        { path: 'client', select: 'name telephone' },
        { path: 'cuisinier', select: 'name telephone address' },
        { path: 'plats.plat', select: 'name price image' }
      ]);
      res.status(200).json({ success: true, message: 'Commande déjà annulée', data: commande });
      return;
    }

    if (st !== 'en_attente') {
      res.status(400).json({ success: false, message: 'Seules les commandes en attente peuvent être annulées' });
      return;
    }

    commande.status = 'annulée';
    await commande.save();

    // Restaurer le stock des plats
    try {
      for (const item of (commande.plats as any[])) {
        await Plat.findByIdAndUpdate(
          item.plat,
          {
            $inc: { stock: Number(item.quantity) },
            $set: { available: true },
          },
          { new: false }
        );
      }
    } catch (e) {
      console.error('Erreur lors de la restauration du stock (annulation client):', e);
    }
    await commande.populate([
      { path: 'client', select: 'name telephone' },
      { path: 'cuisinier', select: 'name telephone address' },
      { path: 'plats.plat', select: 'name price image' }
    ]);

    res.status(200).json({ success: true, message: 'Commande annulée', data: commande });
  } catch (error: any) {
    console.error('Erreur lors de l\'annulation de la commande:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de l\'annulation' });
  }
};
