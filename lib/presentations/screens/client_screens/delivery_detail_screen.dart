import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:simple_food/services/cart_service.dart';
import 'package:simple_food/services/commande_service.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/services/plat_service.dart';
import 'package:geolocator/geolocator.dart';

enum DeliveryPaymentTiming { payOnDelivery, payNow }

// Pour l'instant on ne supporte qu'Orange Money côté app.
enum SimulationPaymentMethod { orange }

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _villeCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _paymentPhoneCtrl = TextEditingController();
  final _paymentOtpCtrl = TextEditingController();

  SimulationPaymentMethod _selectedMethod = SimulationPaymentMethod.orange;
  DeliveryPaymentTiming _timing = DeliveryPaymentTiming.payOnDelivery;
  bool _submitting = false;

  double? _deliveryLat;
  double? _deliveryLng;

  double? _estimatedDeliveryFee;
  bool _estimatingFee = false;

  double get _subtotal => CartService.instance.total;

  double get _total => _subtotal; // total des articles, sans livraison

  String get _paymentStatus =>
      _timing == DeliveryPaymentTiming.payNow ? 'paid' : 'pending';

  Map<String, dynamic>? get _paymentInfo {
    if (_timing != DeliveryPaymentTiming.payNow) return null;
    return {
      'provider': describeEnum(_selectedMethod),
      'phone': _paymentPhoneCtrl.text.trim(),
      'otp': _paymentOtpCtrl.text.trim(),
      'amount': _total.toStringAsFixed(0),
    };
  }

  @override
  void dispose() {
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    _adresseCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _paymentPhoneCtrl.dispose();
    _paymentOtpCtrl.dispose();
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
      _deliveryLat = pos.latitude;
      _deliveryLng = pos.longitude;
      _locationCtrl.text = 'Lat:${pos.latitude}, Lng:${pos.longitude}';
    });

    // Tenter de calculer une estimation des frais de livraison
    _estimateDeliveryFee();
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // rayon de la Terre en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Future<void> _estimateDeliveryFee() async {
    // Besoin de la position du client
    if (_deliveryLat == null || _deliveryLng == null) {
      return;
    }

    final items = CartService.instance.items.value;
    if (items.isEmpty) return;

    final firstPlatId = items.first.id;

    setState(() {
      _estimatingFee = true;
    });

    try {
      final res = await PlatService.getPlatById(firstPlatId);
      if (res['success'] != true) {
        if (!mounted) return;
        setState(() {
          _estimatedDeliveryFee = null;
          _estimatingFee = false;
        });
        return;
      }

      final plat = res['plat'];
      // Plat.fromJson renvoie cuisinierInfo à partir du champ peuplé 'cuisinier'
      final Map<String, dynamic>? cuisinierInfo = plat.cuisinierInfo;

      if (cuisinierInfo == null) {
        if (!mounted) return;
        setState(() {
          _estimatedDeliveryFee = null;
          _estimatingFee = false;
        });
        return;
      }

      final kitchenLat = (cuisinierInfo['kitchenLat'] as num?)?.toDouble();
      final kitchenLng = (cuisinierInfo['kitchenLng'] as num?)?.toDouble();
      if (kitchenLat == null || kitchenLng == null) {
        if (!mounted) return;
        setState(() {
          _estimatedDeliveryFee = null;
          _estimatingFee = false;
        });
        return;
      }

      final baseFee =
          (cuisinierInfo['deliveryBaseFee'] as num?)?.toDouble() ?? 1000;
      final feePerKm =
          (cuisinierInfo['deliveryFeePerKm'] as num?)?.toDouble() ?? 150;

      final distKm = _haversineKm(
        kitchenLat,
        kitchenLng,
        _deliveryLat!,
        _deliveryLng!,
      );

      final rawFee = baseFee + feePerKm * distKm;
      final est = rawFee.isFinite ? rawFee.ceilToDouble() : null;

      if (!mounted) return;
      setState(() {
        _estimatedDeliveryFee = est;
        _estimatingFee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _estimatedDeliveryFee = null;
        _estimatingFee = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ApiService.isAuthenticated) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (_timing == DeliveryPaymentTiming.payNow &&
        (_paymentPhoneCtrl.text.trim().isEmpty ||
            _paymentOtpCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complétez les infos de paiement')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final plats = CartService.instance.items.value
          .map((e) => {'plat': e.id, 'quantity': e.quantity})
          .toList();
      final address =
          '${_villeCtrl.text.trim()}, ${_quartierCtrl.text.trim()}, ${_adresseCtrl.text.trim()}';

      final res = await CommandeService.createCommande(
        plats: plats,
        deliveryAddress: address,
        deliveryPhone: _phoneCtrl.text.trim(),
        deliveryLat: _deliveryLat,
        deliveryLng: _deliveryLng,
        paymentMethod: _timing == DeliveryPaymentTiming.payNow
            ? describeEnum(_selectedMethod)
            : null,
        paymentStatus: _paymentStatus,
        paymentInfo: _paymentInfo,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        CartService.instance.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Commande créée')));
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Détail livraison')),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService.instance.items,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(child: Text('Votre panier est vide'));
          }
          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé des articles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.quantity} x ${item.price.toStringAsFixed(0)} FCFA',
                        ),
                        trailing: Text(
                          '${(item.price * item.quantity).toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    _buildInfoField('Ville', _villeCtrl),
                    const SizedBox(height: 8),
                    _buildInfoField('Quartier', _quartierCtrl),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Localisation (obligatoire)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          tooltip: 'Me localiser',
                          onPressed: _localiser,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse détaillée (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoField(
                      'Téléphone (+226...)',
                      _phoneCtrl,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sous-total : ${_subtotal.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (_estimatedDeliveryFee != null) ...[
                      Text(
                        'Frais de livraison estimés : ${_estimatedDeliveryFee!.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total estimé : ${(_subtotal + _estimatedDeliveryFee!).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '(Le total final peut légèrement varier, les frais exacts sont confirmés côté serveur)',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ] else ...[
                      const Text(
                        'Frais de livraison : calculés automatiquement en fonction de la distance',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total (hors livraison) : ${_total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                    const Divider(height: 32),
                    const Text(
                      'Paiement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<DeliveryPaymentTiming>(
                      title: const Text('Payer à la livraison'),
                      value: DeliveryPaymentTiming.payOnDelivery,
                      groupValue: _timing,
                      onChanged: (v) => setState(() => _timing = v!),
                    ),
                    RadioListTile<DeliveryPaymentTiming>(
                      title: const Text('Payer maintenant'),
                      value: DeliveryPaymentTiming.payNow,
                      groupValue: _timing,
                      onChanged: (v) => setState(() => _timing = v!),
                    ),
                    if (_timing == DeliveryPaymentTiming.payNow)
                      _buildPaymentFields(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (facultatif)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Confirmer et commander'),
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    final bool required =
        label.toLowerCase().contains('téléphone') || // téléphone requis
        label.toLowerCase() == 'ville' ||
        label.toLowerCase() == 'quartier';
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (!required) return null; // champ optionnel
        return (v == null || v.trim().isEmpty) ? 'Requis' : null;
      },
    );
  }

  Widget _buildPaymentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode de paiement : Orange Money'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _paymentPhoneCtrl,
          decoration: const InputDecoration(labelText: 'Numéro utilisé'),
          keyboardType: TextInputType.phone,
          validator: (v) =>
              (v == null || v.trim().length < 6) ? 'Numéro invalide' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _paymentOtpCtrl,
          decoration: const InputDecoration(labelText: 'Code OTP'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'OTP requis' : null,
        ),
      ],
    );
  }
}

String describeEnum(Object value) {
  final description = value.toString();
  final index = description.indexOf('.');
  return index == -1 ? description : description.substring(index + 1);
}
