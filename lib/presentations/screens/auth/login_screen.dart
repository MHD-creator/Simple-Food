import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/auth/preinscription_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/home_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/index_screen.dart';
import 'package:simple_food/presentations/screens/livreur_screen.dart/index_screen.dart';
import 'package:simple_food/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String _countryCode = '+226';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _tryLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        telephone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connexion réussie'),
              backgroundColor: Colors.green,
            ),
          );

          // Rediriger selon le rôle de l'utilisateur
          final user = result['user'];
          if (user.role == 'cuisinier') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CookerDashboard()),
            );
          } else if (user.role == 'livreur') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LivreurDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreenClient()),
            );
          }
        }
      } else {
        if (mounted) {
          String message = result['message'] ?? 'Erreur de connexion';

          // Afficher les erreurs de validation spécifiques
          if (result['errors'] != null && result['errors'].isNotEmpty) {
            final errors = result['errors'] as List;
            message = errors.map((e) => e['msg'] ?? e).join('\n');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
      print('ccccccccc $result');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion au serveur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre numéro de téléphone';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) {
      return 'Numéro trop court';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/simple_food_bg.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),

                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E3A25),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connectez-vous avec votre numéro de téléphone',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 28),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Champ téléphone (avec country code simple)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Country code dropdown simple (text + chevron)
                            InkWell(
                              onTap: () {
                                // Optionnel : afficher picker de pays
                                _showCountryPicker();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _countryCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E3A25),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const VerticalDivider(
                              width: 12,
                              thickness: 1,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),

                            // Input numéro
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Numéro de téléphone',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  isDense: true,
                                ),
                                validator: _validatePhone,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Champ mot de passe
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            hintText: 'Mot de passe',
                            hintStyle: TextStyle(color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Bouton connexion
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _tryLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Connexion...'),
                                  ],
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bouton pour continuer sans se connecter
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HomeScreenClient(),
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Continuer sans se connecter',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Ou séparation
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'ou',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Lien vers la préinscription
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pas encore de compte ?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreinscriptionScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Texte bas
                Text(
                  'SimpleFood © ${DateTime.now().year} — C.M.Y',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Petite boîte de sélection de pays très simple
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        // Exemple réduit : tu peux remplacer par un package 'country_picker' si nécessaire
        final countries = [
          {'name': 'Burkina Faso', 'code': '+226'},
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sélectionner le code du pays',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...countries.map(
                (c) => ListTile(
                  title: Text(c['name']!),
                  trailing: Text(c['code']!),
                  onTap: () {
                    setState(() => _countryCode = c['code']!);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}
