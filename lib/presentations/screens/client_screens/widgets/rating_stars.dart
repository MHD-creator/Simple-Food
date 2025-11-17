import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  const RatingStars({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }
}
