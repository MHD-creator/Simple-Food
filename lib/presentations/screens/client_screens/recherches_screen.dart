import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'widgets/plat_card.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> allPlats = [
    {
      'nom': 'Poulet braisé',
      'image': 'https://images.unsplash.com/photo-1601050690597-1aef4dfc8fda',
      'prix': 2500,
      'note': 4.5,
      'categorie': 'Nourriture',
    },
    {
      'nom': 'Jus de bissap',
      'image': 'https://images.unsplash.com/photo-1617112028762-cf9b3cc6d2b4',
      'prix': 1000,
      'note': 4.8,
      'categorie': 'Boisson',
    },
  ];

  List<Map<String, dynamic>> filtered = [];

  void rechercher(String query) {
    setState(() {
      filtered = allPlats
          .where(
            (plat) =>
                plat['nom'].toLowerCase().contains(query.toLowerCase()) ||
                plat['categorie'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    filtered = allPlats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rechercher un plat")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              onChanged: rechercher,
              decoration: InputDecoration(
                hintText: "Ex : poulet, jus, riz...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          rechercher('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Aucun résultat trouvé"))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final plat = filtered[index];
                      return PlatCard(
                        plat: plat,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlatDetailsScreen(plat: plat),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
