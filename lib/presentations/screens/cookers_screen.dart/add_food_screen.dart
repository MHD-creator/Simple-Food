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
  String categorie = 'Nourriture';
  bool disponible = true;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Liste de prix multiples (ex: petit, moyen, grand)
  List<Map<String, dynamic>> prixList = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nomCtrl = TextEditingController(text: widget.plat?['nom'] ?? '');
    descCtrl = TextEditingController(text: widget.plat?['desc'] ?? '');
    categorie = widget.plat?['categorie'] ?? 'Nourriture';
    disponible = widget.plat?['disponible'] ?? true;

    if (widget.plat?['images'] != null) {
      for (var path in widget.plat!['images']) {
        _images.add(File(path));
      }
    }

    if (widget.plat?['prixList'] != null) {
      prixList = List<Map<String, dynamic>>.from(widget.plat!['prixList']);
    } else {
      prixList = [
        {'label': 'Standard', 'prix': ''},
      ];
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
      String? imageUrl;
      if (_images.isNotEmpty) {
        final upload = await PlatService.uploadImage(_images.first);
        if (upload['success'] == true) {
          imageUrl = upload['url'] as String;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(upload['message']?.toString() ?? 'Echec de l\'upload de l\'image')),
          );
        }
      }
      final result = await PlatService.createPlat(
        name: nomCtrl.text.trim(),
        description: descCtrl.text.trim(),
        price: price,
        categoryLabel: categorie,
        ingredients: const [],
        preparationTime: 20,
        image: imageUrl,
        available: disponible,
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
                ],
                onChanged: (v) => setState(() => categorie = v!),
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
