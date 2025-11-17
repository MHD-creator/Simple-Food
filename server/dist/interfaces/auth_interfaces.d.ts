export interface ClientSignupInterface {
    nom: string;
    age?: number;
    telephone: string;
    password: string;
    confirmPassword: string;
}
export interface CookerSignupInterface {
    nom: string;
    prenom: string;
    telephone: string;
    ville: string;
    quartier: string;
    specialite: string;
    titrePublic: string;
    password: string;
    confirmPassword: string;
}
export interface LoginInterface {
    telephone: string;
    password: string;
}
//# sourceMappingURL=auth_interfaces.d.ts.map