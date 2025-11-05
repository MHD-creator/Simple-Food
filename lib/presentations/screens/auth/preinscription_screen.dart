import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/auth/client_register_screen.dart';
import 'package:simple_food/presentations/screens/auth/cooker_register_screen.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';

class PreinscriptionScreen extends StatelessWidget {
  const PreinscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF6),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            }, 
            child: Text("Connexion >", style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold))
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/simple_food_bg.png', 
                  width: 200,
                ),
                const SizedBox(height: 20),

                // Titre principal
                const Text(
                  'Bienvenue sur Simple Food',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E3A25),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Choisissez votre type d’inscription pour continuer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Carte Cuisinier
                _buildChoiceCard(
                  context,
                  title: 'Je suis un Cuisinier',
                  icon: Icons.restaurant_menu,
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CookerRegisterScreen())
                      );
                  },
                ),
                const SizedBox(height: 20),

                // Carte Client
                _buildChoiceCard(
                  context,
                  title: 'Je suis un Client',
                  icon: Icons.person,
                  color: Colors.greenAccent,
                  onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClientRegisterScreen())
                     );
                  },
                ),

                const SizedBox(height: 50),
                // Petit texte de bas de page
                const Text(
                  'SimpleFood © 2025 — C.M.Y',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 28,
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3A25),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
