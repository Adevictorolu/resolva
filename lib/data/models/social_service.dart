import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Model representing a social media platform in Bigisub Marketing Hub.
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

/// Model representing a social media boosting service from Bigisub Marketing Hub
/// (`GET https://api.bigisub.ng/api/v2/marketinghub/services/`).
class SocialService {
  final String id;
  final int bigisubServiceId;
  final String platformId;
  final String country;
  final String name;
  final String description;
  final String category;
  final double pricePerUnit;
  final double displayAmount;
  final String displayUnit;
  final String pricingModel;
  final int minQuantity;
  final int maxQuantity;
  final String estimatedDelivery;
  final bool requiresCustomText;
  final String serviceType;
  final bool hasDripfeed;
  final bool hasRefill;
  final bool hasCancel;
  final String deliverySpeed;
  final double? avgDeliveryHours;
  final double? successRate;

  const SocialService({
    required this.id,
    this.bigisubServiceId = 0,
    required this.platformId,
    this.country = 'global',
    required this.name,
    required this.description,
    required this.category,
    required this.pricePerUnit,
    double? displayAmount,
    this.displayUnit = 'per 1000',
    this.pricingModel = 'per_1000',
    required this.minQuantity,
    required this.maxQuantity,
    required this.estimatedDelivery,
    this.requiresCustomText = false,
    this.serviceType = 'Default',
    this.hasDripfeed = false,
    this.hasRefill = false,
    this.hasCancel = false,
    this.deliverySpeed = 'fast',
    this.avgDeliveryHours,
    this.successRate,
  }) : displayAmount = displayAmount ??
            (pricingModel == 'per_1000' ? pricePerUnit * 1000 : pricePerUnit);

  /// Calculates the exact Naira cost for [qty] units following Bigisub's pricing model.
  double calculatePrice(int qty) {
    if (qty <= 0) return 0;
    if (pricingModel == 'per_1000') {
      if (minQuantity == 1 && maxQuantity == 1 && displayAmount > pricePerUnit) {
        return displayAmount * qty;
      }
      final exactUnitRate =
          displayAmount > 0 ? (displayAmount / 1000.0) : pricePerUnit;
      return exactUnitRate * qty;
    }
    return pricePerUnit * qty;
  }

  /// Starting price for the minimum allowed quantity.
  double get startingPrice => calculatePrice(minQuantity);

  /// Human-readable country label.
  String get countryLabel {
    return switch (country.toLowerCase()) {
      'nigeria' => 'Nigeria',
      'ghana' => 'Ghana',
      _ => 'Global',
    };
  }

  /// Normalized high-level category for quick filter tabs.
  String get normalizedCategory {
    final lower = '$category $name'.toLowerCase();
    if (lower.contains('follower') ||
        lower.contains('subscribe') ||
        lower.contains('member') ||
        lower.contains('page follow')) {
      return 'Followers & Subscribers';
    }
    if (lower.contains('like') ||
        lower.contains('reaction') ||
        lower.contains('emotion')) {
      return 'Likes & Reactions';
    }
    if (lower.contains('view') ||
        lower.contains('stream') ||
        lower.contains('play') ||
        lower.contains('watch') ||
        lower.contains('impression') ||
        lower.contains('reach')) {
      return 'Views & Streams';
    }
    if (lower.contains('comment') || lower.contains('reply')) {
      return 'Comments & Replies';
    }
    if (lower.contains('share') ||
        lower.contains('repost') ||
        lower.contains('retweet') ||
        lower.contains('save') ||
        lower.contains('vote') ||
        lower.contains('poll')) {
      return 'Shares, Saves & Votes';
    }
    return 'Other Engagement';
  }

  /// Extracted service rules & instructions for the user before ordering.
  List<String> get serviceRules {
    final rules = <String>[];
    if (description.trim().isNotEmpty) {
      for (final line in description.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) rules.add(trimmed);
      }
    }
    if (serviceType == 'Subscriptions') {
      rules.add(
        'Enter your target username only (without @ and without https:// URL).',
      );
    } else {
      rules.add(
        'Ensure your profile, page, or post is set to PUBLIC before placing the order.',
      );
      rules.add(
        'Submit a direct, valid link to the profile, post, reel, or video.',
      );
    }
    if (requiresCustomText ||
        serviceType == 'Custom Comments' ||
        serviceType == 'Custom Comments Package') {
      rules.add(
        'Enter your custom comments/text (one comment per line).',
      );
    }
    if (serviceType == 'Poll') {
      rules.add('Specify the poll option number (1, 2, 3...) to vote for.');
    }
    if (serviceType == 'Mentions Hashtag') {
      rules.add('Enter a single hashtag without the # symbol.');
    }
    rules.add(
      hasRefill
          ? 'Refill Guarantee: Free refill is supported on completed/partial orders within 24–48 hours.'
          : 'No Refill: This service does not include automatic refill.',
    );
    if (hasCancel) {
      rules.add(
        'Cancellable: Active orders can be cancelled (undelivered portion refunded to wallet).',
      );
    }
    return rules;
  }

  factory SocialService.fromBigisubJson(Map<String, dynamic> json) {
    final idVal = (json['id'] as num?)?.toInt() ?? 0;
    final rawPlatform = (json['platform'] ?? 'other').toString().toLowerCase();
    final platformId = rawPlatform == 'x' ? 'twitter' : rawPlatform;
    final pricingModel = (json['pricing_model'] ?? 'per_1000').toString();
    final price = double.tryParse('${json['price'] ?? 0}') ?? 0.0;
    final displayAmt = double.tryParse(
          '${json['display_amount'] ?? (json['price_display'] is Map ? json['price_display']['amount'] : null) ?? (pricingModel == 'per_1000' ? price * 1000 : price)}',
        ) ??
        price;
    final displayUnit = (json['display_unit'] ??
            (json['price_display'] is Map
                ? json['price_display']['unit']
                : null) ??
            (pricingModel == 'per_1000' ? 'per 1000' : 'per unit'))
        .toString();
    final perUnitPrice = double.tryParse(
          '${json['per_unit_price'] ?? (json['price_display'] is Map ? json['price_display']['per_unit_price'] : null) ?? price}',
        ) ??
        price;

    final speed = (json['delivery_speed'] ??
            (json['quality'] is Map ? json['quality']['delivery_speed'] : null) ??
            'fast')
        .toString();
    final avgHours = (json['avg_delivery_hours'] as num?)?.toDouble() ??
        (json['quality'] is Map
            ? (json['quality']['avg_delivery_hours'] as num?)?.toDouble()
            : null);
    final successRate = (json['success_rate'] as num?)?.toDouble() ??
        (json['quality'] is Map
            ? (json['quality']['success_rate'] as num?)?.toDouble()
            : null);

    String estDelivery;
    if (avgHours != null && avgHours > 0) {
      if (avgHours < 1) {
        estDelivery = 'Instant (~${(avgHours * 60).round().clamp(1, 59)} mins)';
      } else {
        estDelivery = '~${avgHours.toStringAsFixed(1)} hrs ($speed)';
      }
    } else {
      estDelivery = switch (speed.toLowerCase()) {
        'instant' => 'Instant (0–1 hr)',
        'fast' => 'Fast (1–6 hrs)',
        'medium' => 'Medium (6–24 hrs)',
        _ => '0–24 hours',
      };
    }

    return SocialService(
      id: 'bgs-$idVal',
      bigisubServiceId: idVal,
      platformId: platformId,
      country: (json['country'] ?? 'global').toString().toLowerCase(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      pricePerUnit: perUnitPrice,
      displayAmount: displayAmt,
      displayUnit: displayUnit,
      pricingModel: pricingModel,
      minQuantity: (json['min_quantity'] as num?)?.toInt() ?? 10,
      maxQuantity: (json['max_quantity'] as num?)?.toInt() ?? 10000,
      estimatedDelivery: estDelivery,
      requiresCustomText: json['requires_custom_text'] == true,
      serviceType: (json['service_type'] ?? 'Default').toString(),
      hasDripfeed: json['has_dripfeed'] == true,
      hasRefill: json['has_refill'] == true,
      hasCancel: json['has_cancel'] == true,
      deliverySpeed: speed,
      avgDeliveryHours: avgHours,
      successRate: successRate,
    );
  }
}
