import 'package:flutter/material.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/models/user.dart';
import 'package:simple_food/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class CookerProfileScreen extends StatefulWidget {
  const CookerProfileScreen({super.key});

  @override
  State<CookerProfileScreen> createState() => _CookerProfileScreenState();
}

class _CookerProfileScreenState extends State<CookerProfileScreen> {
  bool _loading = false;
  String? _error;
  User? _user;
  final _baseFeeCtrl = TextEditingController();
  final _feePerKmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _updateDeliverySettings() async {
    try {
      final base = double.tryParse(_baseFeeCtrl.text.trim());
      final perKm = double.tryParse(_feePerKmCtrl.text.trim());
      if (base == null || base < 0 || perKm == null || perKm < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Montants invalides')));
        return;
      }
      final res = await ApiService.put('/auth/delivery-settings', {
        'deliveryBaseFee': base,
        'deliveryFeePerKm': perKm,
      });
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres de livraison enregistrés.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour des paramètres.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _updateKitchenLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez activer la localisation sur votre appareil.',
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final res = await ApiService.put('/auth/kitchen-location', {
        'kitchenLat': pos.latitude,
        'kitchenLng': pos.longitude,
      });

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localisation de la cuisine enregistrée.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de la localisation.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService.getProfile();
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _user = res['user'] as User;
          _baseFeeCtrl.text = (_user!.deliveryBaseFee ?? 1000).toStringAsFixed(
            0,
          );
          _feePerKmCtrl.text = (_user!.deliveryFeePerKm ?? 150).toStringAsFixed(
            0,
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'Erreur';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Changer le mot de passe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe actuel',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe (min 6)',
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 caractères' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                    ),
                    validator: (v) =>
                        (v != newCtrl.text) ? 'Ne correspond pas' : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSt(() => submitting = true);
                              final res = await AuthService.changePassword(
                                currentPassword: currentCtrl.text.trim(),
                                newPassword: newCtrl.text.trim(),
                                confirmNewPassword: confirmCtrl.text.trim(),
                              );
                              if (!mounted) return;
                              setSt(() => submitting = false);
                              if (res['success'] == true) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mot de passe mis à jour'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message']?.toString() ?? 'Erreur',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                      label: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil cuisinier'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              child: Text(
                                ((_user?.name ?? 'U'))
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_user?.name ?? 'Utilisateur').toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  (_user?.email ?? '').toString(),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _infoRow('Téléphone', (_user?.telephone ?? '')),
                                _infoRow('Adresse', (_user?.address ?? '')),
                                _infoRow('Rôle', (_user?.role ?? '')),
                                if (_user?.createdAt != null)
                                  _infoRow(
                                    'Créé le',
                                    _user!.createdAt.toString(),
                                  ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Paramètres de livraison',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _baseFeeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Frais de base (FCFA)',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _feePerKmCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tarif par km (FCFA/km)',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _updateDeliverySettings,
                                  icon: const Icon(Icons.delivery_dining),
                                  label: const Text(
                                    'Enregistrer les frais de livraison',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _updateKitchenLocation,
                                  icon: const Icon(Icons.location_on),
                                  label: const Text(
                                    'Enregistrer la localisation de ma cuisine',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Déconnexion'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
