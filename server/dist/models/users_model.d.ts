import mongoose, { Document } from "mongoose";
export interface IUser extends Document {
    name: string;
    telephone: string;
    password: string;
    role: 'client' | 'cuisinier' | 'admin';
    age?: number;
    email?: string;
    address?: string;
    profileImage?: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    comparePassword(candidatePassword: string): Promise<boolean>;
}
export declare const User: mongoose.Model<IUser, {}, {}, {}, mongoose.Document<unknown, {}, IUser, {}, {}> & IUser & Required<{
    _id: unknown;
}> & {
    __v: number;
}, any>;
//# sourceMappingURL=users_model.d.ts.map