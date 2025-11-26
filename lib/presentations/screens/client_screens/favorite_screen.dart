import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';
import 'package:simple_food/services/favorites_service.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  List<Map<String, dynamic>> favoris = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await FavoritesService.getAll();
    if (!mounted) return;
    setState(() => favoris = list);
  }

  Future<void> _supprimerFavori(int index) async {
    final item = favoris[index];
    await FavoritesService.toggle(item);
    await _load();
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
                      onPressed: () => _supprimerFavori(index),
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
