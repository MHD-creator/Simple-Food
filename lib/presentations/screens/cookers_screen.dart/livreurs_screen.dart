import 'package:flutter/material.dart';
import 'package:simple_food/services/livreur_service.dart';

class CookerLivreursScreen extends StatefulWidget {
  const CookerLivreursScreen({super.key});

  @override
  State<CookerLivreursScreen> createState() => _CookerLivreursScreenState();
}

class _CookerLivreursScreenState extends State<CookerLivreursScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _livreurs = [];
  bool _showInactive = false;

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
    final res = await LivreurService.getLivreurs();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _livreurs = (res['data'] as List<Map<String, dynamic>>);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? current}) async {
    final nameController = TextEditingController(
      text: current?['name']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: current?['telephone']?.toString() ?? '',
    );
    final passwordController = TextEditingController();

    final isEdit = current != null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Modifier le livreur' : 'Nouveau livreur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'Nouveau mot de passe (optionnel)'
                        : 'Mot de passe',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final tel = phoneController.text.trim();
                final pwd = passwordController.text.trim();
                if (name.isEmpty || tel.isEmpty || (!isEdit && pwd.isEmpty)) {
                  return;
                }
                Navigator.pop(ctx);
                if (isEdit) {
                  await LivreurService.updateLivreur(
                    id: current!['id']?.toString() ?? current['_id'].toString(),
                    name: name,
                    telephone: tel,
                    password: pwd.isEmpty ? null : pwd,
                  );
                } else {
                  await LivreurService.createLivreur(
                    name: name,
                    telephone: tel,
                    password: pwd,
                  );
                }
                await _load();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLivreur(Map<String, dynamic> livreur) async {
    final id = (livreur['id'] ?? livreur['_id'] ?? '').toString();
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Désactiver ce livreur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LivreurService.deleteLivreur(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livreurs'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Livreurs actifs: '
                          '${_livreurs.where((l) => (l['isActive'] ?? true) == true).length}',
                        ),
                        Row(
                          children: [
                            const Text('Afficher désactivés'),
                            Switch(
                              value: _showInactive,
                              onChanged: (v) {
                                setState(() => _showInactive = v);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredLivreurs().isEmpty
                        ? const Center(child: Text('Aucun livreur'))
                        : ListView.builder(
                            itemCount: _filteredLivreurs().length,
                            itemBuilder: (context, index) {
                              final l = _filteredLivreurs()[index];
                              final name = (l['name'] ?? '').toString();
                              final tel = (l['telephone'] ?? '').toString();
                              final active = (l['isActive'] ?? true) == true;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: active
                                      ? Colors.green
                                      : Colors.grey,
                                  child: const Icon(
                                    Icons.delivery_dining,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(name.isEmpty ? 'Livreur' : name),
                                subtitle: Row(
                                  children: [
                                    Expanded(child: Text(tel)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        active ? 'Actif' : 'Désactivé',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: active
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showForm(current: l),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteLivreur(l),
                                    ),
                                  ],
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

extension on _CookerLivreursScreenState {
  List<Map<String, dynamic>> _filteredLivreurs() {
    if (_showInactive) return _livreurs;
    return _livreurs.where((l) => (l['isActive'] ?? true) == true).toList();
  }
}
