# Simple Food – Rapport de projet

## 1. Description générale

Simple Food est une application mobile Flutter couplée à un backend Node.js/Express et une base de données MongoDB. 

L’objectif principal est de permettre à des utilisateurs (clients) de :
- découvrir des plats faits maison proposés par des cuisiniers,
- parcourir les menus et les catégories,
- ajouter des plats à un panier,
- passer commande de manière simple et rapide.

Le projet inclut :
- une application Flutter (dossier `lib/`) pour l’interface utilisateur,
- un serveur backend Node.js/Express (dossier `server/`) pour la gestion des utilisateurs, des plats, des commandes, etc.

---

## 2. Fonctionnalités principales (côté Flutter)

- **Authentification**
  - Inscription (`AuthService.register`) avec rôle par défaut `client`.
  - Connexion (`AuthService.login`) via téléphone et mot de passe.
  - Stockage sécurisé du token JWT dans `SharedPreferences` via `ApiService`.
  - Récupération du profil (`AuthService.getProfile`).
  - Déconnexion (`AuthService.logout`) qui efface le token.

- **Onboarding / écran de bienvenue**
  - Premier lancement : affichage d’un écran d’onboarding multi-pages (`OnboardingScreen`) qui explique les grandes lignes de l’application.
  - Stockage d’un booléen `has_seen_onboarding` dans `SharedPreferences`.
  - L’onboarding n’est affiché qu’une seule fois ; ensuite, l’utilisateur arrive directement sur l’écran de connexion ou d’accueil.

- **Gestion du panier**
  - Service `CartService` pour stocker les éléments du panier.
  - `CartStorage` persiste le panier en local (chargé au démarrage dans `main.dart`).
  - Sauvegarde automatique du panier à chaque modification (
    `CartService.instance.items.addListener(() async { await CartStorage.save(); });`).

- **Navigation et écrans clients**
  - Écran d’accueil client `HomeScreenClient`.
  - Widgets de présentation des plats comme `PlatCard`.
  - Organisation des écrans dans `lib/presentations/screens/...` (authentification, client, écran de bienvenue, écrans admin/cuisiniers, etc.).

- **Gestion des appels API**
  - `ApiService` centralise les appels HTTP (`get`, `post`, `put`, `delete`).
  - Ajout automatique du header `Authorization: Bearer <token>` si l’utilisateur est connecté.
  - Méthode utilitaire `uploadMultipart` pour envoyer des fichiers (images de plats, par exemple).

---

## 3. Fonctionnement de l’application Flutter

### 3.1. Démarrage (`main.dart`)

1. Initialisation Flutter : `WidgetsFlutterBinding.ensureInitialized()`.
2. Initialisation du service API : `ApiService.init()` lit le token stocké dans `SharedPreferences`.
3. Chargement du panier : `CartStorage.load()`.
4. Mise en place d’un listener pour sauvegarder le panier à chaque changement.
5. Lecture de `has_seen_onboarding` dans `SharedPreferences`.
6. Vérification de l’authentification de l’utilisateur via `ApiService.isAuthenticated`.
7. Lancement de l’app : `runApp(MyApp(isLoggedIn: loggedIn, hasSeenOnboarding: hasSeenOnboarding));`.

### 3.2. Widget racine `MyApp`

Dans `_MyAppState` :
- `_loading` : indique si on est encore en phase de validation du token/profil.
- `_loggedIn` : état d’authentification.
- `_hasSeenOnboarding` : indique si l’onboarding a déjà été vu.

Flow :
- Si `_loading == true` : affiche un `CircularProgressIndicator`.
- Sinon :
  - Si `_hasSeenOnboarding == false` : affiche `OnboardingScreen`.
  - Si `_hasSeenOnboarding == true` :
    - Si `_loggedIn == true` : `HomeScreenClient`.
    - Sinon : `LoginScreen`.

La validation du token se fait via `AuthService.getProfile()`. En cas d’échec, le token est supprimé et l’utilisateur est considéré comme déconnecté.

---

## 4. Architecture backend (dossier `server/`)

- Backend écrit en **Node.js** avec **Express** et **TypeScript**.
- Base de données **MongoDB** via **Mongoose**.
- Authentification JWT avec `jsonwebtoken`.
- Sécurité :
  - `bcryptjs` pour le hash des mots de passe.
  - `express-validator` pour valider les entrées.
- Gestion des fichiers (par ex. images de plats) via `multer`.
- Configuration : variables d’environnement gérées avec `dotenv`.

Scripts principaux (dans `server/package.json`) :
- `npm run dev` : démarre le serveur en mode développement avec `ts-node`.
- `npm run build` : compile TypeScript vers JavaScript (dossier `dist`).
- `npm start` : démarre le serveur à partir de `dist/app.js`.

Le serveur expose des routes API consommées par l’application Flutter (par ex. `/api/auth/login`, `/api/auth/register`, `/api/auth/profile`, ainsi que des endpoints pour les plats, commandes, etc.).

---

## 5. Pile technologique

- **Front (mobile)** :
  - Flutter (Dart) – Material Design.
  - Bibliothèques principales (pubspec.yaml) :
    - `http` : appels HTTP REST vers le backend.
    - `shared_preferences` : stockage local (token, onboarding, etc.).
    - `image_picker` : sélection d’images (ex. photo de plat).
    - `fl_chart` : graphiques (statistiques côté admin/cuisinier si utilisés).
    - `geolocator` : géolocalisation (par ex. localisation client/cuisinier si utilisé).
    - `carousel_slider` : carrousels (ex. pour les images ou promotions).

- **Back (server)** :
  - Node.js + Express.
  - MongoDB + Mongoose.
  - JWT pour l’authentification.
  - TypeScript pour la robustesse du code backend.

---

## 6. Installation et exécution

### 6.1. Prérequis

- Flutter SDK (version compatible avec Dart SDK ^3.9.2).
- Node.js & npm.
- Instance MongoDB accessible (locale ou en ligne).

### 6.2. Installation du projet Flutter

Dans le dossier `simple_food/` :

```bash
flutter pub get
```

Puis pour lancer l’application :

```bash
flutter run
```

(Choisir l’émulateur ou le device cible selon votre environnement.)

### 6.3. Installation et lancement du backend

Dans le dossier `simple_food/server/` :

```bash
npm install
```

Configurer les variables d’environnement (par ex. dans un fichier `.env`) :

- `MONGODB_URI` : URI de connexion à MongoDB.
- `JWT_SECRET` : secret pour signer les tokens JWT.
- Tout autre paramètre nécessaire (port, etc.).

Pour démarrer en mode développement :

```bash
npm run dev
```

Pour construire et lancer en production :

```bash
npm run build
npm start
```

Le frontend Flutter est configuré (dans `ApiService.baseUrl`) pour pointer vers l’API HTTP, par exemple :

```dart
static const String baseUrl = 'http://10.18.76.41:3001/api';
```

Adapter cette URL selon l’environnement selon vos donnee(port, ip ou localhost)

---

## 7. Structure du projet (vue d’ensemble)

```text
simple_food/
├─ lib/
│  ├─ main.dart                  # Point d’entrée Flutter, routing global, onboarding
│  ├─ services/
│  │  ├─ api_service.dart        # Appels HTTP + token + upload multipart
│  │  ├─ auth_service.dart       # Authentification (login, register, profil, logout)
│  │  ├─ cart_service.dart       # Gestion du panier (logique métier)
│  │  ├─ cart_storage.dart       # Persistance locale du panier
│  ├─ models/                    # Modèles Dart (User, Plats, Commandes, etc.)
│  ├─ presentations/
│  │  ├─ screens/
│  │  │  ├─ auth/                # Écrans de connexion/inscription
│  │  │  ├─ client_screens/      # Écrans pour les clients (home, liste de plats, etc.)
│  │  │  ├─ admin_screen/        # Écrans administrateur 
│  │  │  ├─ cookers_screen.dart  # Écrans cuisiniers
│  │  │  ├─ welcome_screen/
│  │  │  │  └─ onboarding_screen.dart  # Onboarding multi-pages
│  │  ├─ widgets/                # Widgets réutilisables
│  └─ ...
│
├─ server/
│  ├─ src/                       # Code TypeScript (Express, routes, modèles Mongoose)
│  ├─ dist/                      # Code compilé JavaScript
│  ├─ package.json               # Dépendances et scripts backend
│  └─ ...
│
├─ assets/                       # Images, icônes, etc. 
├─ README.md                     # Ce rapport (version Markdown)
└─ rapport.txt                   # Version texte du rapport
```

---

## 8. Évolutions possibles

- Ajout de tests unitaires et de tests widget côté Flutter.
- Ajout de tests d’intégration côté backend (Jest, supertest).

- Amélioration de la gestion d’état pour des écrans complexes.
- Système de notifications (commandes prêtes, mises à jour de statut, etc.).

---


