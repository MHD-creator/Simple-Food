import 'package:flutter/material.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/orders_detail_screen.dart';

class CookerOrdersScreen extends StatefulWidget {
  const CookerOrdersScreen({super.key});

  @override
  State<CookerOrdersScreen> createState() => _CookerOrdersScreenState();
}

class _CookerOrdersScreenState extends State<CookerOrdersScreen> {
  bool _loading = false;
  String? _error;
  List<dynamic> commandes = [];
  String selectedStatus = 'Tous';
  String sortBy = 'date_desc';
  String searchQuery = '';
  final List<String> statuses = const [
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

  List<String> _allowedStatuses(String current) {
    const chain = ['en_attente', 'en_preparation', 'en_livraison', 'livrée'];
    final idx = chain.indexOf(current);
    final List<String> out = [];
    if (idx != -1 && idx < chain.length - 1) {
      out.add(chain[idx + 1]);
    }
    if (current != 'livrée' && current != 'annulée') {
      out.add('annulée');
    }
    return out;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final status = selectedStatus == 'Tous' ? null : selectedStatus;
    final res = await CommandeService.getCommandes(status: status);
    if (!mounted) return;
    if (res['success'] == true) {
      final list = (res['data'] as List).toList();
      _applySort(list);
      setState(() {
        commandes = list;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur';
        _loading = false;
      });
    }
  }

  List<dynamic> _filteredCommandes() {
    if (searchQuery.trim().isEmpty) return commandes;
    final q = searchQuery.trim().toLowerCase();
    return commandes.where((e) {
      final m = (e as Map).cast<String, dynamic>();
      final id = (m['_id'] ?? m['id'] ?? '').toString().toLowerCase();
      final name = (m['client']?['name'] ?? '').toString().toLowerCase();
      return id.contains(q) || name.contains(q);
    }).toList();
  }

  void _applySort(List list) {
    int cmpNum(num a, num b) => a.compareTo(b);
    int cmpDate(DateTime a, DateTime b) => a.compareTo(b);
    if (sortBy == 'amount_desc') {
      list.sort(
        (a, b) => cmpNum(
          (b['totalAmount'] ?? 0) as num,
          (a['totalAmount'] ?? 0) as num,
        ),
      );
    } else if (sortBy == 'status') {
      list.sort(
        (a, b) => (a['status'] ?? '').toString().compareTo(
          (b['status'] ?? '').toString(),
        ),
      );
    } else {
      // date_desc par défaut
      list.sort((a, b) {
        final ad =
            DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return cmpDate(bd, ad);
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Mettre à jour le statut en "$status" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await CommandeService.updateStatus(id: id, status: status);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) {
              setState(() {
                sortBy = s;
              });
              _applySort(commandes);
              setState(() {});
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'date_desc',
                child: Text('Trier: Date (récent)'),
              ),
              PopupMenuItem(
                value: 'amount_desc',
                child: Text('Trier: Montant'),
              ),
              PopupMenuItem(value: 'status', child: Text('Trier: Statut')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher: nom client ou ID commande',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              itemBuilder: (_, i) {
                final s = statuses[i];
                final sel = s == selectedStatus;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => selectedStatus = s);
                      _load();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null
                      ? Center(child: Text(_error!))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            itemCount: _filteredCommandes().length,
                            itemBuilder: (_, i) {
                              final list = _filteredCommandes();
                              final c = list[i] as Map<String, dynamic>;
                              final id = (c['_id'] ?? c['id'] ?? '').toString();
                              final status = (c['status'] ?? '').toString();
                              final totalNum =
                                  (c['totalAmount'] ?? c['total'] ?? 0) as num;
                              final deliveryFee =
                                  (c['deliveryFee'] ?? 0) as num;
                              final subtotal = deliveryFee > 0
                                  ? (totalNum - deliveryFee)
                                  : totalNum;
                              final total = totalNum.toInt().toString();
                              final client =
                                  c['client'] as Map<String, dynamic>?;
                              final name = (client?['name'] ?? 'Client')
                                  .toString();
                              final plats = (c['plats'] as List?) ?? [];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cmd #${id.isNotEmpty ? id.substring(0, 6) : '------'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(status),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CookerOrderDetailScreen(id: id),
                                          ),
                                        ),
                                        child: Text(
                                          'Client: $name',
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: plats.map((p) {
                                          final pp = p as Map<String, dynamic>;
                                          final q = (pp['quantity'] ?? 1)
                                              .toString();
                                          final pl =
                                              pp['plat']
                                                  as Map<String, dynamic>?;
                                          final nom = (pl?['name'] ?? 'Plat')
                                              .toString();
                                          return Chip(label: Text('$nom x$q'));
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sous-total: ${subtotal.toInt()} F',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (deliveryFee > 0)
                                                Text(
                                                  'Livraison: ${deliveryFee.toInt()} F',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              Text(
                                                'Total: $total F',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (s) =>
                                                _updateStatus(id, s),
                                            itemBuilder: (_) {
                                              final opts = _allowedStatuses(
                                                status,
                                              );
                                              return opts
                                                  .map(
                                                    (s) => PopupMenuItem(
                                                      value: s,
                                                      child: Text(s),
                                                    ),
                                                  )
                                                  .toList();
                                            },
                                            child: Icon(
                                              Icons.edit,
                                              color:
                                                  _allowedStatuses(
                                                    status,
                                                  ).isEmpty
                                                  ? Colors.grey
                                                  : Colors.blue,
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
                        )),
          ),
        ],
      ),
    );
  }
}
