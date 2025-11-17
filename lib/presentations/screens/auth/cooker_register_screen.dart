import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/services/auth_service.dart';

class CookerRegisterScreen extends StatefulWidget {
  const CookerRegisterScreen({super.key});

  @override
  State<CookerRegisterScreen> createState() => _CookerRegisterScreenState();
}

class _CookerRegisterScreenState extends State<CookerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _titrePublicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final List<String> _specialites = ['Boisson', 'Nourriture'];
  String? _selectedSpecialite;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _telephoneController.dispose();
    _specialiteController.dispose();
    _titrePublicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        name: '${_prenomController.text.trim()} ${_nomController.text.trim()}',
        telephone: _telephoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'cuisinier',
        address: '${_villeController.text.trim()}, ${_quartierController.text.trim()}',
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inscription réussie'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Rediriger vers la page de connexion
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          String message = result['message'] ?? 'Erreur lors de l\'inscription';
          
          // Afficher les erreurs de validation spécifiques
          if (result['errors'] != null && result['errors'].isNotEmpty) {
            final errors = result['errors'] as List;
            message = errors.map((e) => e['msg'] ?? e).join('\n');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF6),
        shadowColor: const Color(0xFFFDFBF6),
      foregroundColor:Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/simple_food_bg.png', width: 200),
              Center(
                child: ListTile(
                  title: Text("Inscription en tant que cuisinier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  subtitle: Text("Veuillez remplir tout les champs"),
                )
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _prenomController,
                decoration: _inputDecoration('Prénom'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nomController,
                decoration: _inputDecoration('Nom'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _titrePublicController,
                decoration: _inputDecoration('Titre public (visible aux clients)'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Spécialité'),
                value: _selectedSpecialite,
                items: _specialites
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSpecialite = v),
                validator: (v) =>
                    v == null ? 'Veuillez choisir une spécialité' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _villeController,
                decoration: _inputDecoration('Ville'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _quartierController,
                decoration: _inputDecoration('Quartier'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Téléphone'),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('Mot de passe').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    v!.length < 6 ? 'Au moins 6 caractères' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration('Confirmer le mot de passe').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => v != _passwordController.text
                    ? 'Les mots de passe ne correspondent pas'
                    : null,
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text(
                          "S'inscrire",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 18),
               Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Déja un compte ?", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen()
                    )
                  ),
                child: const Text('Se connecter', style: TextStyle(color: Colors.blue),),
              ),
             
            ],
          ),
        ),
      ),
    );
  }
}
