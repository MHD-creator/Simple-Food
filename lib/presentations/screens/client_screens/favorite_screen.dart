import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final List<Map<String, dynamic>> favoris = [
    {
      'id': 1,
      'nom': 'Poulet braisé',
      'image':
          'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',

      'prix': 2500,
      'note': 4.5,
    },
  ];

  void supprimerFavori(int index) {
    setState(() {
      favoris.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customClientAppBar('Mes favoris', null, context),
      body: favoris.isEmpty
          ? const Center(child: Text("Aucun plat favori"))
          : ListView.builder(
              itemCount: favoris.length,
              itemBuilder: (context, index) {
                final plat = favoris[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(plat['image'], width: 60),
                    ),
                    title: Text(plat['nom']),
                    subtitle: Text("${plat['prix']} FCFA"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => supprimerFavori(index),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlatDetailsScreen(plat: plat),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: customNavBar(2, null, context),
    );
  }
}
