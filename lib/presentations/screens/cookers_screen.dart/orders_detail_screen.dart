import 'package:flutter/material.dart';
import 'package:simple_food/services/commande_service.dart';

class CookerOrderDetailScreen extends StatefulWidget {
  final String id;
  const CookerOrderDetailScreen({super.key, required this.id});

  @override
  State<CookerOrderDetailScreen> createState() =>
      _CookerOrderDetailScreenState();
}

class _CookerOrderDetailScreenState extends State<CookerOrderDetailScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? commande;

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
    final res = await CommandeService.getCommandeById(widget.id);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        commande = (res['data'] as Map).cast<String, dynamic>();
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
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
    final res = await CommandeService.updateStatus(
      id: widget.id,
      status: status,
    );
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
      appBar: AppBar(title: const Text('Détail commande')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
                ? Center(child: Text(_error!))
                : (commande == null
                      ? const SizedBox.shrink()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Commande #${(commande!['_id'] ?? '').toString().substring(0, 6)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (commande!['status'] ?? '').toString(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _statusTimeline(
                                (commande!['status'] ?? '').toString(),
                              ),
                              const SizedBox(height: 8),
                              if (commande!['createdAt'] != null)
                                Text(
                                  'Créée le: ${commande!['createdAt']}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Client: ${(commande!['client']?['name'] ?? 'Client').toString()}',
                              ),
                              Text(
                                'Téléphone: ${(commande!['client']?['telephone'] ?? '').toString()}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adresse livraison: ${(commande!['deliveryAddress'] ?? '').toString()}',
                              ),
                              Text(
                                'Téléphone livraison: ${(commande!['deliveryPhone'] ?? '').toString()}',
                              ),
                              if (commande!['notes'] != null &&
                                  (commande!['notes'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Notes: ${commande!['notes']}'),
                                ),
                              const Divider(height: 24),
                              const Text(
                                'Plats',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...((commande!['plats'] as List?) ?? []).map((p) {
                                final pp = (p as Map).cast<String, dynamic>();
                                final q = (pp['quantity'] ?? 1).toString();
                                final pl = (pp['plat'] as Map?)
                                    ?.cast<String, dynamic>();
                                final nom = (pl?['name'] ?? 'Plat').toString();
                                final price = (pp['price'] ?? pl?['price'] ?? 0)
                                    .toString();
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(nom),
                                  subtitle: Text(
                                    'Quantité: $q • Prix: $price F',
                                  ),
                                );
                              }).toList(),
                              const Divider(height: 24),
                              Text(
                                'Total: ${(commande!['totalAmount'] ?? 0).toString()} F',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Actions statut',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _allowedStatuses(
                                  (commande!['status'] ?? '').toString(),
                                ).map((s) => _statusBtn(s)).toList(),
                              ),
                            ],
                          ),
                        ))),
    );
  }

  Widget _statusBtn(String s) {
    return OutlinedButton(onPressed: () => _updateStatus(s), child: Text(s));
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

  Widget _statusTimeline(String current) {
    final steps = ['en_attente', 'en_preparation', 'en_livraison', 'livrée'];
    int currentIndex = steps.indexOf(current);
    if (currentIndex == -1) currentIndex = 0;
    final cancelled = current == 'annulée';

    Color dotColor(int i) {
      if (cancelled) return Colors.red;
      return i <= currentIndex ? Colors.green : Colors.grey.shade400;
    }

    Color lineColor(int i) {
      if (cancelled) return Colors.red.shade200;
      return i < currentIndex ? Colors.green : Colors.grey.shade300;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _dot(dotColor(i)),
              if (i < steps.length - 1)
                Expanded(child: Container(height: 2, color: lineColor(i))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps
              .map(
                (s) => Expanded(
                  child: Text(
                    s,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: cancelled && s != 'annulée'
                          ? Colors.red
                          : (s == current ? Colors.black : Colors.black54),
                      fontWeight: s == current
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        if (cancelled)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Commande annulée',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}
