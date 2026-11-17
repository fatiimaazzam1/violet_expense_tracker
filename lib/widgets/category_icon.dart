import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.iconKey,
    this.size = 18,
    this.color,
    super.key,
  });

  final String iconKey;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconFor(iconKey), size: size, color: color);
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'food' => Icons.restaurant_outlined,
      'transport' => Icons.directions_transit_outlined,
      'bills' => Icons.receipt_long_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      _ => Icons.category_outlined,
    };
  }
}
