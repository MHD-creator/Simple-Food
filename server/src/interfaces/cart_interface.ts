import type { PlatInterface } from "./plat_interface.js";

export interface CartInterface{
    clientId: string,
    plat: PlatInterface;
    number: number,
    createdAt: Date

}