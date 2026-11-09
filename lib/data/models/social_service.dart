import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Model representing a social media platform.
class SocialPlatform {
  final String id;
  final String name;
  final FaIconData icon;
  final Color color;

  const SocialPlatform({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Model representing a social media service offering.
class SocialService {
  final String id;
  final String platformId;
  final String name;
  final String description;
  final String category;
  final double pricePerUnit;
  final int minQuantity;
  final int maxQuantity;
  final String estimatedDelivery;

  const SocialService({
    required this.id,
    required this.platformId,
    required this.name,
    required this.description,
    required this.category,
    required this.pricePerUnit,
    required this.minQuantity,
    required this.maxQuantity,
    required this.estimatedDelivery,
  });

  double get startingPrice => pricePerUnit * minQuantity;
}
