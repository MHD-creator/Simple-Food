import 'package:flutter/material.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/orders_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LivreurDashboard extends StatefulWidget {
  const LivreurDashboard({super.key});

  @override
  State<LivreurDashboard> createState() => _LivreurDashboardState();
}

class _LivreurDashboardState extends State<LivreurDashboard> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _commandes = [];
  String _selectedStatus = 'Tous';

  final List<String> _statuses = const [
    'Tous',
    'en_attente',
    'en_preparation',
    'en_livraison',
    'livrée',
    'annulée',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await CommandeService.getCommandes(page: 1, limit: 50);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _commandes = (res['data'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final res = await CommandeService.updateStatus(id: id, status: status);
    if (!mounted) return;
    if (res['success'] == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Erreur')),
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir l'application Téléphone"),
        ),
      );
    }
  }

  Future<void> _openDirections(Map<String, dynamic> commande) async {
    final lat = commande['deliveryLat'];
    final lng = commande['deliveryLng'];
    final address = (commande['deliveryAddress'] ?? '').toString();

    // 1) Construire un URI natif pour l'appli de navigation (Google Maps)
    Uri? nativeUri;
    if (lat is num && lng is num) {
      // URI de navigation directe Google Maps (Android)
      nativeUri = Uri.parse(
        'google.navigation:q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}&mode=d',
      );
    } else if (address.isNotEmpty) {
      // Fallback: recherche par adresse texte
      final encoded = Uri.encodeComponent(address);
      nativeUri = Uri.parse('google.navigation:q=$encoded&mode=d');
    }

    // 2) Construire un URI HTTPS générique pour Google Maps (navigateur)
    Uri? webUri;
    if (lat is num && lng is num) {
      webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}&travelmode=driving',
      );
    } else if (address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving',
      );
    }

    if (nativeUri == null && webUri == null) {
      return;
    }

    bool opened = false;

    // Essayer d'abord l'URI natif (appli Maps)
    if (nativeUri != null) {
      try {
        opened = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }

    // Puis fallback sur l'URL web dans le navigateur
    if (!opened && webUri != null) {
      try {
        opened = await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir l'itinéraire Google Maps"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace livreur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ApiService.clearToken();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: _statuses.length,
                      itemBuilder: (context, index) {
                        final s = _statuses[index];
                        final sel = s == _selectedStatus;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: sel,
                            onSelected: (_) {
                              setState(() => _selectedStatus = s);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredCommandes().isEmpty
                        ? const Center(
                            child: Text('Aucune commande à afficher'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredCommandes().length,
                            itemBuilder: (context, index) {
                              final c = _filteredCommandes()[index];
                              final id = (c['_id'] ?? c['id'] ?? '').toString();
                              final client = (c['client'] as Map?)
                                  ?.cast<String, dynamic>();
                              final clientName = (client?['name'] ?? 'Client')
                                  .toString();
                              final clientPhone = (c['deliveryPhone'] ?? '')
                                  .toString();
                              final address = (c['deliveryAddress'] ?? '')
                                  .toString();
                              final status = (c['status'] ?? '').toString();

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(
                                    'Cmd #${id.isNotEmpty ? id.substring(0, 6) : '------'}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Client : $clientName'),
                                      if (address.isNotEmpty)
                                        Text('Adresse : $address'),
                                      Text('Statut : $status'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.map),
                                            tooltip: 'Itinéraire',
                                            onPressed: () => _openDirections(c),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.phone),
                                            onPressed: clientPhone.isEmpty
                                                ? null
                                                : () => _callPhone(clientPhone),
                                          ),
                                        ],
                                      ),
                                      if (status != 'livrée')
                                        PopupMenuButton<String>(
                                          onSelected: (value) =>
                                              _updateStatus(id, value),
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'en_livraison',
                                              child: Text('Démarrer livraison'),
                                            ),
                                            PopupMenuItem(
                                              value: 'livrée',
                                              child: Text('Marquer livrée'),
                                            ),
                                          ],
                                          child: const Icon(Icons.more_vert),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CookerOrderDetailScreen(id: id),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

extension on _LivreurDashboardState {
  List<Map<String, dynamic>> _filteredCommandes() {
    if (_selectedStatus == 'Tous') return _commandes;
    return _commandes
        .where((c) => ((c['status'] ?? '').toString() == _selectedStatus))
        .toList();
  }
}
