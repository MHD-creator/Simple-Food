import type { PlatInterface } from "./plat_interface.js";

export type StatutCommande = 'En cours' | 'Livrée' | 'Annulée' | 'En préparation';
export interface CommandeInterface {
    id: number;
    statut: StatutCommande; 
    date: string; 
    total: number;
    plats: PlatInterface[]; 
}