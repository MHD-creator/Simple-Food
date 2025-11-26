import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_food/services/plat_service.dart';

class AddFoodScreen extends StatefulWidget {
  final Map<String, dynamic>? plat;
  const AddFoodScreen({super.key, this.plat});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomCtrl;
  late TextEditingController descCtrl;
  late TextEditingController prepCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController promoPercentCtrl;
  String categorie = 'Nourriture';
  bool disponible = true;
  bool promoActive = false;
  DateTime? promoStart;
  DateTime? promoEnd;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Liste de prix multiples (ex: petit, moyen, grand)
  List<Map<String, dynamic>> prixList = [];
  bool _isSaving = false;
  List<String> ingredients = [];

  @override
  void initState() {
    super.initState();
    nomCtrl = TextEditingController(text: widget.plat?['nom'] ?? '');
    descCtrl = TextEditingController(text: widget.plat?['desc'] ?? '');
    final dynamic rawPrep =
        widget.plat?['preparationTime'] ??
        widget.plat?['tempsPreparation'] ??
        widget.plat?['temps_preparation'] ??
        20;
    prepCtrl = TextEditingController(text: rawPrep.toString());
    final dynamic rawStock = widget.plat?['stock'] ?? 0;
    stockCtrl = TextEditingController(text: rawStock.toString());
    final dynamic rawPromoPercent = widget.plat?['promoPercent'] ?? 0;
    promoPercentCtrl = TextEditingController(text: rawPromoPercent.toString());
    categorie = widget.plat?['categorie'] ?? 'Nourriture';
    disponible = widget.plat?['disponible'] ?? true;
    promoActive = (widget.plat?['promoActive'] ?? false) == true;
    try {
      final s = widget.plat?['promoStart'];
      final e = widget.plat?['promoEnd'];
      if (s is String && s.isNotEmpty) promoStart = DateTime.tryParse(s);
      if (e is String && e.isNotEmpty) promoEnd = DateTime.tryParse(e);
    } catch (_) {}

    if (widget.plat?['images'] != null) {
      for (var path in widget.plat!['images']) {
        _images.add(File(path));
      }

      // Stock
      final stock = int.tryParse(stockCtrl.text.trim());
      if (stock == null || stock < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le stock doit être un entier >= 0')),
        );
        return;
      }
    }

    if (widget.plat?['prixList'] != null) {
      prixList = List<Map<String, dynamic>>.from(widget.plat!['prixList']);
    } else {
      prixList = [
        {'label': 'Standard', 'prix': ''},
      ];
    }

    final rawIngr = widget.plat?['ingredients'];
    if (rawIngr is List) {
      ingredients = rawIngr
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _addPrix() {
    setState(() {
      prixList.add({'label': '', 'prix': ''});
    });
  }

  void _removePrix(int index) {
    setState(() => prixList.removeAt(index));
  }

  void _addIngredient() {
    setState(() => ingredients.add(''));
  }

  void _removeIngredient(int index) {
    setState(() => ingredients.removeAt(index));
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      double price = 0;
      if (prixList.isNotEmpty) {
        final p = prixList.first['prix'];
        if (p is num) price = p.toDouble();
        if (p is String) price = double.tryParse(p) ?? 0;
      }
      if (price <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le prix doit être supérieur à 0')),
        );
        return;
      }
      // Validation temps de préparation
      final prep = int.tryParse(prepCtrl.text.trim());
      if (prep == null || prep < 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le temps de préparation doit être au moins 5 minutes',
            ),
          ),
        );
        return;
      }

      // Normaliser ingrédients
      final ingr = ingredients
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      String? imageUrl;
      List<String> imagesUrls = [];
      if (_images.isNotEmpty) {
        for (final f in _images) {
          final upload = await PlatService.uploadImage(f);
          if (upload['success'] == true && upload['url'] != null) {
            imagesUrls.add(upload['url'] as String);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  upload['message']?.toString() ??
                      'Echec de l\'upload de l\'image',
                ),
              ),
            );
          }
        }
        if (imagesUrls.isNotEmpty) imageUrl = imagesUrls.first;
      }
      // Construire la liste des variantes de prix à envoyer
      final List<Map<String, dynamic>> pricesPayload = prixList
          .map((e) {
            final lbl = (e['label'] ?? '').toString().trim();
            final raw = e['prix'];
            final pr = raw is num
                ? raw.toDouble()
                : double.tryParse(raw?.toString() ?? '') ?? 0.0;
            if (lbl.isEmpty) return null;
            return {'label': lbl, 'price': pr};
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();

      final stock = int.tryParse(stockCtrl.text.trim());
      final double? promoPercent = double.tryParse(
        promoPercentCtrl.text.trim(),
      );
      final result = widget.plat == null
          ? await PlatService.createPlat(
              name: nomCtrl.text.trim(),
              description: descCtrl.text.trim(),
              price: price,
              categoryLabel: categorie,
              ingredients: ingr,
              preparationTime: prep,
              image: imageUrl,
              available: disponible,
              prices: pricesPayload.isNotEmpty ? pricesPayload : null,
              images: imagesUrls.isNotEmpty ? imagesUrls : null,
              stock: stock,
              promoActive: promoActive,
              promoPercent: promoPercent,
              promoStart: promoStart,
              promoEnd: promoEnd,
            )
          : await PlatService.updatePlat(
              id: (widget.plat!['id'] ?? widget.plat!['_id'] ?? '').toString(),
              name: nomCtrl.text.trim(),
              description: descCtrl.text.trim(),
              price: price,
              categoryLabel: categorie,
              ingredients: ingr,
              preparationTime: prep,
              image: imageUrl,
              available: disponible,
              prices: pricesPayload.isNotEmpty ? pricesPayload : null,
              images: imagesUrls.isNotEmpty ? imagesUrls : null,
              stock: stock,
              promoActive: promoActive,
              promoPercent: promoPercent,
              promoStart: promoStart,
              promoEnd: promoEnd,
            );
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pop(context, result['plat']);
      } else {
        final msg = result['message'] ?? 'Erreur lors de l\'enregistrement';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        print(result);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plat != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          isEdit ? 'Modifier le plat' : 'Ajouter un plat',
          style: const TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du plat',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Veuillez entrer un nom de plat' : null,
              ),
              const SizedBox(height: 12),

              // === Liste des prix dynamiques ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prix du plat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...prixList.asMap().entries.map((entry) {
                int index = entry.key;
                var prix = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: prix['label'],
                        decoration: const InputDecoration(
                          hintText: 'Label (ex: Petit, Moyen...)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => prix['label'] = v,
                        validator: (v) => v!.isEmpty ? 'Entrez un label' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: prix['prix'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Prix (F CFA)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => prix['prix'] = v,
                        validator: (v) => v!.isEmpty ? 'Entrez un prix' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removePrix(index),
                    ),
                  ],
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addPrix,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un prix'),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: categorie,
                items: const [
                  DropdownMenuItem(
                    value: 'Nourriture',
                    child: Text('Nourriture'),
                  ),
                  DropdownMenuItem(value: 'Boisson', child: Text('Boisson')),
                  DropdownMenuItem(value: 'Dessert', child: Text('Dessert')),
                  DropdownMenuItem(
                    value: 'Fast-food',
                    child: Text('Fast-food'),
                  ),
                  DropdownMenuItem(
                    value: 'Asiatique',
                    child: Text('Asiatique'),
                  ),
                  DropdownMenuItem(value: 'Européen', child: Text('Européen')),
                ],
                onChanged: (v) => setState(() => categorie = v ?? 'Nourriture'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Sélectionnez une catégorie'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.trim().isEmpty
                    ? 'Veuillez entrer une description'
                    : null,
              ),
              const SizedBox(height: 16),

              // === Promotion ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Promotion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Activer la promotion'),
                value: promoActive,
                activeColor: Colors.redAccent,
                onChanged: (v) => setState(() => promoActive = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: promoPercentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Réduction (%)',
                  hintText: 'Ex: 20',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (!promoActive) return null;
                  final d = double.tryParse(v?.trim() ?? '');
                  if (d == null) return 'Entrez un pourcentage valide';
                  if (d < 0 || d > 90) return 'Entre 0 et 90%';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: promoStart ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => promoStart = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        promoStart == null
                            ? 'Début (optionnel)'
                            : 'Début: ${promoStart!.toLocal().toString().split(' ').first}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: promoEnd ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => promoEnd = picked);
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        promoEnd == null
                            ? 'Fin (optionnel)'
                            : 'Fin: ${promoEnd!.toLocal().toString().split(' ').first}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      promoActive = false;
                      promoPercentCtrl.text = '0';
                      promoStart = null;
                      promoEnd = null;
                    });
                  },
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  label: const Text('Annuler la promo'),
                ),
              ),
              const SizedBox(height: 16),

              // === Stock ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stock disponible',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex: 10',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final val = int.tryParse(v?.trim() ?? '');
                  if (val == null || val < 0) return 'Entrez un entier >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // === Temps de préparation ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Temps de préparation (minutes)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: prepCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex: 20',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final val = int.tryParse(v?.trim() ?? '');
                  if (val == null || val < 5) return 'Minimum 5 minutes';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // === Ingrédients ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ingrédients',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...ingredients.asMap().entries.map((entry) {
                final i = entry.key;
                final value = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: value,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Tomate',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => ingredients[i] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: () => _removeIngredient(i),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un ingrédient'),
                ),
              ),
              const SizedBox(height: 16),

              // === Images ===
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Images du plat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    int index = entry.key;
                    File img = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            img,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Disponible à la commande'),
                value: disponible,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => disponible = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _sauvegarder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Modifier' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
