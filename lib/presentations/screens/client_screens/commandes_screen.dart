import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_client_appbar.dart';
import 'package:simple_food/presentations/screens/client_screens/details_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/custom_navbar.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  String selectedStatus = "Tous";
  List<dynamic> commandes = [];
  bool _loading = false;
  String? _error;

  List<String> filtres = [
    "Tous",
    "en_attente",
    "en_preparation",
    "en_livraison",
    "livrée",
    "annulée",
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ApiService.isAuthenticated) {
      setState(() {
        commandes = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final status = selectedStatus == 'Tous' ? null : selectedStatus;
    final res = await CommandeService.getCommandes(status: status);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        commandes = res['data'] as List;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur';
        _loading = false;
      });
    }
  }

  Future<void> _annuler(String id) async {
    final res = await CommandeService.cancelCommande(id);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commande annulée')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isAuthenticated) {
      return Scaffold(
        appBar: customClientAppBar("Mes commandes", null, context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Connectez-vous pour voir vos commandes"),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: customNavBar(1, null, context),
      );
    }
    final filtered = commandes;

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
                  final isSelected =
                      selectedStatus == status ||
                      (selectedStatus == 'Tous' && status == 'Tous');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) async {
                        setState(() => selectedStatus = status);
                        await _load();
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Vous n'avez encore aucune commande.",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    0,
                                    10,
                                    10,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final commande =
                                        filtered[index] as Map<String, dynamic>;
                                    final status =
                                        (commande['status'] ??
                                                commande['statut'] ??
                                                '')
                                            .toString();
                                    final id =
                                        (commande['_id'] ??
                                                commande['id'] ??
                                                '')
                                            .toString();
                                    final plats =
                                        (commande['plats'] as List?) ?? [];
                                    final createdAt =
                                        (commande['createdAt'] ?? '')
                                            .toString();
                                    final total =
                                        (commande['totalAmount'] ??
                                                commande['total'] ??
                                                0)
                                            .toString();

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          _showCommandeDetails(commande),
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Commande #${id.isNotEmpty ? id.substring(0, 6) : '------'}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (createdAt.isNotEmpty)
                                                        Text(
                                                          "Créée le : $createdAt",
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        "${plats.length} plat(s)",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        status,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),

                                              // Miniatures des plats
                                              if (plats.isNotEmpty)
                                                SizedBox(
                                                  height: 85,
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: plats.length,
                                                    itemBuilder: (context, i) {
                                                      final plat = plats[i];
                                                      final platObj =
                                                          plat
                                                              is Map<
                                                                String,
                                                                dynamic
                                                              >
                                                          ? plat
                                                          : <String, dynamic>{};
                                                      final platData =
                                                          platObj['plat'] ??
                                                          platObj;

                                                      String _baseOrigin() {
                                                        final uri = Uri.parse(
                                                          ApiService.baseUrl,
                                                        );
                                                        final port = uri.hasPort
                                                            ? ':${uri.port}'
                                                            : '';
                                                        return '${uri.scheme}://${uri.host}$port';
                                                      }

                                                      String _normalizeImage(
                                                        String? src,
                                                      ) {
                                                        if (src == null ||
                                                            src.isEmpty) {
                                                          return '';
                                                        }
                                                        final lower = src
                                                            .toLowerCase();
                                                        final isHttp =
                                                            lower.startsWith(
                                                              'http://',
                                                            ) ||
                                                            lower.startsWith(
                                                              'https://',
                                                            );
                                                        final isLocal =
                                                            lower.startsWith(
                                                              'file://',
                                                            ) ||
                                                            lower.startsWith(
                                                              'c:',
                                                            ) ||
                                                            lower.startsWith(
                                                              'd:',
                                                            ) ||
                                                            lower.startsWith(
                                                              '/storage',
                                                            );
                                                        if (isLocal) return src;
                                                        if (isHttp) return src;
                                                        final origin =
                                                            _baseOrigin();
                                                        return src.startsWith(
                                                              '/',
                                                            )
                                                            ? '$origin$src'
                                                            : '$origin/$src';
                                                      }

                                                      final imgUrl =
                                                          _normalizeImage(
                                                            (platData['image'] ??
                                                                    '')
                                                                .toString(),
                                                          );
                                                      final name =
                                                          (platData['name'] ??
                                                                  'Plat')
                                                              .toString();
                                                      final price =
                                                          (platData['price'] ??
                                                                  0)
                                                              .toString();

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => PlatDetailsScreen(
                                                                plat: {
                                                                  'id':
                                                                      (platData['_id'] ??
                                                                              '')
                                                                          .toString(),
                                                                  'nom': name,
                                                                  'image':
                                                                      imgUrl,
                                                                  'prix':
                                                                      double.tryParse(
                                                                        price,
                                                                      ) ??
                                                                      0,
                                                                  'note': 0,
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          width: 80,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                right: 10,
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                child:
                                                                    imgUrl
                                                                        .isEmpty
                                                                    ? _placeholderBox()
                                                                    : Image.network(
                                                                        imgUrl,
                                                                        height:
                                                                            55,
                                                                        width:
                                                                            70,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder:
                                                                            (
                                                                              _,
                                                                              __,
                                                                              ___,
                                                                            ) =>
                                                                                _placeholderBox(),
                                                                      ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                name,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          12,
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Total : $total FCFA",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (status == 'en_attente')
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        "Annuler",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _confirmerAnnulation(
                                                            context,
                                                            id,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ))),
          ),
        ],
      ),
      bottomNavigationBar: customNavBar(1, null, context),
    );
  }

  void _showCommandeDetails(Map<String, dynamic> commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final status = (commande['status'] ?? commande['statut'] ?? '')
            .toString();
        final id = (commande['_id'] ?? commande['id'] ?? '').toString();
        final plats = (commande['plats'] as List?) ?? [];
        final total = (commande['totalAmount'] ?? commande['total'] ?? 0)
            .toString();
        final address = (commande['deliveryAddress'] ?? '').toString();
        final phone = (commande['deliveryPhone'] ?? '').toString();
        final notes = (commande['notes'] ?? '').toString();
        final createdAt = (commande['createdAt'] ?? '').toString();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              controller: controller,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Commande #${id.isNotEmpty ? id.substring(0, 6) : '------'}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (createdAt.isNotEmpty)
                  Text(
                    'Créée le : $createdAt',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Livraison',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (address.isNotEmpty) Text('Adresse : $address'),
                if (phone.isNotEmpty) Text('Téléphone : $phone'),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Notes : $notes'),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Plats',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...plats.map((p) {
                  final pp = (p as Map).cast<String, dynamic>();
                  final q = (pp['quantity'] ?? 1).toString();
                  final platData =
                      (pp['plat'] as Map?)?.cast<String, dynamic>() ?? pp;
                  final name = (platData['name'] ?? 'Plat').toString();
                  final price = (pp['price'] ?? platData['price'] ?? 0)
                      .toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text('Quantité : $q • Prix : $price FCFA'),
                  );
                }).toList(),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$total FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderBox({double width = 70, double height = 55}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEFEFEF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.black26,
        size: 18,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'en_preparation':
        return Colors.blueAccent;
      case 'en_livraison':
        return Colors.purple;
      case 'livrée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmerAnnulation(BuildContext context, String id) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              await _annuler(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }
}
