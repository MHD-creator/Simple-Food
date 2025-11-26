import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:simple_food/services/cart_service.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';

class CheckoutModal extends StatefulWidget {
  final List<Map<String, dynamic>>? overridePlats;
  const CheckoutModal({super.key, this.overridePlats});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final _formKey = GlobalKey<FormState>();
  final _villeCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    _adresseCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _localiser() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission localisation refusée')),
      );
      return;
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _adresseCtrl.text = 'Lat:${pos.latitude}, Lng:${pos.longitude}';
    });
  }

  Future<void> _commander() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ApiService.isAuthenticated) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _submitting = true);
    try {
      final plats =
          widget.overridePlats ??
          CartService.instance.items.value
              .map((e) => {'plat': e.id, 'quantity': e.quantity})
              .toList();
      final addr =
          '${_villeCtrl.text.trim()}, ${_quartierCtrl.text.trim()}, ${_adresseCtrl.text.trim()}';
      final res = await CommandeService.createCommande(
        plats: plats,
        deliveryAddress: addr,
        deliveryPhone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res['success'] == true) {
        if (widget.overridePlats == null) {
          CartService.instance.clear();
        }
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Commande créée')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Erreur')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finaliser la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _villeCtrl,
                        decoration: const InputDecoration(labelText: 'Ville'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _quartierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quartier',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adresseCtrl,
                  decoration: InputDecoration(
                    labelText: 'Adresse détaillée',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _localiser,
                      tooltip: 'Me localiser',
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (+225...)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? 'Téléphone invalide'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _commander,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Commander'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
