import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  String selectedStatus = "Tous";

  final List<Map<String, dynamic>> commandes = [
    {
      'id': 1,
      'statut': 'En cours',
      'date': '05 Nov 2025',
      'total': 5500,
      'plats': [
        {
          'nom': 'Poulet braisé',
          'prix': 2500,
          'image':
              'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
        },
        {
          'nom': 'Jus de bissap',
          'prix': 1000,
          'image':
              'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
        },
      ],
    },
    {
      'id': 2,
      'statut': 'Livrée',
      'date': '01 Nov 2025',
      'total': 3500,
      'plats': [
        {
          'nom': 'Salade César',
          'prix': 2000,
          'image':
              'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
        },
        {
          'nom': 'Smoothie Mangue',
          'prix': 1500,
          'image':
              'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761589371396?alt=media&token=91964b8c-ccad-4950-ace1-d842724d018c',
        },
      ],
    },
    {
      'id': 3,
      'statut': 'Annulée',
      'date': '30 Oct 2025',
      'total': 2000,
      'plats': [
        {
          'nom': 'Pizza Margherita',
          'prix': 2000,
          'image':
              'https://firebasestorage.googleapis.com/v0/b/leneshop-83532.firebasestorage.app/o/produits%2Fproduct_1761588728651?alt=media&token=3d8ab690-848b-4eb9-8b28-6e6080232642',
        },
      ],
    },
  ];

  List<String> filtres = ["Tous", "En cours", "Livrée", "Annulée"];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedStatus == "Tous"
        ? commandes
        : commandes.where((c) => c['statut'] == selectedStatus).toList();

    return Scaffold(
      appBar: customClientAppBar("Mes commandes", null, context),
      body: Column(
        children: [
          // Filtre par statut
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filtres.length,
                itemBuilder: (context, index) {
                  final status = filtres[index];
                  final isSelected = selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => selectedStatus = status);
                      },
                      selectedColor: Colors.deepOrange,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      "Aucune commande trouvée.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final commande = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête commande
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Commande #${commande['id']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        commande['statut'] as String,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      commande['statut'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Date : ${commande['date']}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 10),

                              // Miniatures des plats
                              SizedBox(
                                height: 85,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: commande['plats'].length,
                                  itemBuilder: (context, i) {
                                    final plat = commande['plats'][i];
                                    return GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PlatDetailsScreen(plat: plat),
                                        ),
                                      ),
                                      child: Container(
                                        width: 80,
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                plat['image'],
                                                height: 55,
                                                width: 70,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              plat['nom'],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total : ${commande['total']} FCFA",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (commande['statut'] == 'En cours')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text(
                                        "Annuler",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      onPressed: () => _confirmerAnnulation(
                                        context,
                                        commande['id'],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: customNavBar(1, null, context),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En cours':
        return Colors.orange;
      case 'Livrée':
        return Colors.green;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmerAnnulation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler la commande"),
        content: const Text(
          "Voulez-vous vraiment annuler cette commande ? Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Non"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = commandes.indexWhere(
                  (commande) => commande['id'] == id,
                );
                if (index != -1) {
                  commandes[index]['statut'] = 'Annulée';
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }
}
