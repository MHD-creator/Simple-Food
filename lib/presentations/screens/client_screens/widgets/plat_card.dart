import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/widgets/rating_stars.dart';

class PlatCard extends StatelessWidget {
  final Map<String, dynamic> plat;
  final VoidCallback? onTap;

  const PlatCard({super.key, required this.plat, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Image.network(
                plat['image'],
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plat['nom'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    RatingStars(rating: plat['note']),
                    const SizedBox(height: 5),
                    Text(
                      "${plat['prix']} FCFA",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ajouté aux favoris')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
