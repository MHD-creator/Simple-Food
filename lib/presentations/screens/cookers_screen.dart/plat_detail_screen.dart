import 'dart:io';
import 'package:flutter/material.dart';
import 'package:simple_food/models/plat.dart';

class PlatDetailScreen extends StatelessWidget {
  final Plat plat;
  const PlatDetailScreen({super.key, required this.plat});

  @override
  Widget build(BuildContext context) {
    final tag = 'plat-image-${plat.id}';
    Widget image;
    if (plat.image != null && plat.image!.isNotEmpty) {
      final isFile = plat.image!.startsWith('/') || plat.image!.startsWith('C:');
      image = isFile
          ? Image.file(File(plat.image!), width: double.infinity, height: 220, fit: BoxFit.cover)
          : Image.network(plat.image!, width: double.infinity, height: 220, fit: BoxFit.cover);
    } else {
      image = Image.network(
        'https://via.placeholder.com/800x400.png?text=Plat',
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plat.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: image,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plat.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${plat.price.toStringAsFixed(0)} F",
                    style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(plat.category, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text("${plat.preparationTime} min", style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plat.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        plat.available ? Icons.check_circle : Icons.cancel,
                        color: plat.available ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(plat.available ? 'Disponible' : 'Indisponible'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
