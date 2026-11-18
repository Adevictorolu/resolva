import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/exam_product.dart';
import '../data/models/social_service.dart';
import 'auth_service.dart';
import 'paystack_service.dart';

/// Pricing rule mode for either global categories or individual services.
enum PriceRuleMode {
  /// Percentage markup on top of base rate (e.g. +15% -> base * 1.15).
  percentage,

  /// Fixed Naira amount added to base rate (e.g. +₦200 -> base + 200).
  fixedMarkup,

  /// Exact custom Naira rate replacing the base rate (e.g. ₦5,500).
  exactPrice,
}

/// Rule applied to a specific service or category.
class ServicePriceOverride {
  final String serviceId;
  final PriceRuleMode mode;
  final double value;
  final DateTime updatedAt;

  const ServicePriceOverride({
    required this.serviceId,
    required this.mode,
    required this.value,
    required this.updatedAt,
  });

  double applyTo(double baseRate) {
    final result = switch (mode) {
      PriceRuleMode.percentage => baseRate * (1.0 + (value / 100.0)),
      PriceRuleMode.fixedMarkup => baseRate + value,
      PriceRuleMode.exactPrice => value,
    };
    return result < 0 ? 0 : double.parse(result.toStringAsFixed(2));
  }

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'mode': mode.name,
        'value': value,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ServicePriceOverride.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] ?? 'percentage').toString();
    final mode = PriceRuleMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => PriceRuleMode.percentage,
    );
    return ServicePriceOverride(
      serviceId: (json['serviceId'] ?? '').toString(),
      mode: mode,
      value: (json['value'] is num)
          ? (json['value'] as num).toDouble()
          : (double.tryParse('${json['value']}') ?? 0),
      updatedAt:
          DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
    );
  }
}

/// Platform-wide pricing configuration controlled by Administrators and
/// applied across all customer accounts.
class PlatformPricingConfig {
  /// Global rule for Social Media Boosting services (`percentage` or `fixedMarkup`).
  final PriceRuleMode socialGlobalMode;
  final double socialGlobalValue;

  /// Optional region-specific percentage markups (if != 0, added to region).
  final double globalRegionPercent;
  final double nigeriaRegionPercent;
  final double ghanaRegionPercent;

  /// Global rule for Examination E-Pins (`percentage` or `fixedMarkup`).
  final PriceRuleMode examGlobalMode;
  final double examGlobalValue;

  /// Per-service overrides keyed by service `id` (e.g. `bgs-104` or `exam-1`).
  final Map<String, ServicePriceOverride> overrides;

  /// Additional admin emails synced across the platform.
  final List<String> adminEmails;

  final DateTime updatedAt;

  const PlatformPricingConfig({
    this.socialGlobalMode = PriceRuleMode.percentage,
    this.socialGlobalValue = 0.0,
    this.globalRegionPercent = 0.0,
    this.nigeriaRegionPercent = 0.0,
    this.ghanaRegionPercent = 0.0,
    this.examGlobalMode = PriceRuleMode.percentage,
    this.examGlobalValue = 0.0,
    this.overrides = const {},
    this.adminEmails = const ['ademolavictor869@gmail.com'],
    required this.updatedAt,
  });

  factory PlatformPricingConfig.defaults() => PlatformPricingConfig(
        updatedAt: DateTime.now(),
      );

  /// Calculates the effective customer display rate for a Social Media service.
  double effectiveSocialRate(SocialService service, double baseDisplayAmount) {
    // 1. Check if there is a per-service override (by id or bigisubServiceId)
    final override = overrides[service.id] ??
        overrides['bgs-${service.bigisubServiceId}'];
    if (override != null) {
      return override.applyTo(baseDisplayAmount);
    }

    // 2. Apply global social rule
    double rate = switch (socialGlobalMode) {
      PriceRuleMode.percentage =>
        baseDisplayAmount * (1.0 + (socialGlobalValue / 100.0)),
      PriceRuleMode.fixedMarkup => baseDisplayAmount + socialGlobalValue,
      PriceRuleMode.exactPrice =>
        socialGlobalValue > 0 ? socialGlobalValue : baseDisplayAmount,
    };

    // 3. Apply optional regional percentage adjustment
    final c = service.country.toLowerCase();
    final regPct = c == 'nigeria'
        ? nigeriaRegionPercent
        : (c == 'ghana' ? ghanaRegionPercent : globalRegionPercent);
    if (regPct != 0) {
      rate = rate * (1.0 + (regPct / 100.0));
    }

    return rate < 0 ? 0 : double.parse(rate.toStringAsFixed(2));
  }

  /// Calculates the effective customer price per PIN for an Exam Product.
  double effectiveExamPrice(ExamProduct product, double basePrice) {
    final override = overrides[product.id] ??
        overrides[product.provider.toUpperCase()] ??
        overrides[product.examCode.toUpperCase()];
    if (override != null) {
      return override.applyTo(basePrice);
    }

    final rate = switch (examGlobalMode) {
      PriceRuleMode.percentage =>
        basePrice * (1.0 + (examGlobalValue / 100.0)),
      PriceRuleMode.fixedMarkup => basePrice + examGlobalValue,
      PriceRuleMode.exactPrice =>
        examGlobalValue > 0 ? examGlobalValue : basePrice,
    };
    return rate < 0 ? 0 : double.parse(rate.toStringAsFixed(2));
  }

  PlatformPricingConfig copyWith({
    PriceRuleMode? socialGlobalMode,
    double? socialGlobalValue,
    double? globalRegionPercent,
    double? nigeriaRegionPercent,
    double? ghanaRegionPercent,
    PriceRuleMode? examGlobalMode,
    double? examGlobalValue,
    Map<String, ServicePriceOverride>? overrides,
    List<String>? adminEmails,
    DateTime? updatedAt,
  }) {
    return PlatformPricingConfig(
      socialGlobalMode: socialGlobalMode ?? this.socialGlobalMode,
      socialGlobalValue: socialGlobalValue ?? this.socialGlobalValue,
      globalRegionPercent: globalRegionPercent ?? this.globalRegionPercent,
      nigeriaRegionPercent: nigeriaRegionPercent ?? this.nigeriaRegionPercent,
      ghanaRegionPercent: ghanaRegionPercent ?? this.ghanaRegionPercent,
      examGlobalMode: examGlobalMode ?? this.examGlobalMode,
      examGlobalValue: examGlobalValue ?? this.examGlobalValue,
      overrides: overrides ?? this.overrides,
      adminEmails: adminEmails ?? this.adminEmails,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'socialGlobalMode': socialGlobalMode.name,
        'socialGlobalValue': socialGlobalValue,
        'globalRegionPercent': globalRegionPercent,
        'nigeriaRegionPercent': nigeriaRegionPercent,
        'ghanaRegionPercent': ghanaRegionPercent,
        'examGlobalMode': examGlobalMode.name,
        'examGlobalValue': examGlobalValue,
        'overrides': overrides.map((k, v) => MapEntry(k, v.toJson())),
        'adminEmails': adminEmails,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PlatformPricingConfig.fromJson(Map<String, dynamic> json) {
    PriceRuleMode parseMode(dynamic raw) {
      final str = (raw ?? 'percentage').toString();
      return PriceRuleMode.values.firstWhere(
        (m) => m.name == str,
        orElse: () => PriceRuleMode.percentage,
      );
    }

    double parseNum(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse('$raw') ?? 0.0;
    }

    final rawOverrides = json['overrides'];
    final parsedOverrides = <String, ServicePriceOverride>{};
    if (rawOverrides is Map) {
      rawOverrides.forEach((k, v) {
        if (v is Map) {
          parsedOverrides[k.toString()] =
              ServicePriceOverride.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    final rawAdmins = json['adminEmails'];
    final admins = <String>{'ademolavictor869@gmail.com'};
    if (rawAdmins is List) {
      for (final item in rawAdmins) {
        final email = item.toString().trim().toLowerCase();
        if (email.contains('@')) admins.add(email);
      }
    }

    return PlatformPricingConfig(
      socialGlobalMode: parseMode(json['socialGlobalMode']),
      socialGlobalValue: parseNum(json['socialGlobalValue']),
      globalRegionPercent: parseNum(json['globalRegionPercent']),
      nigeriaRegionPercent: parseNum(json['nigeriaRegionPercent']),
      ghanaRegionPercent: parseNum(json['ghanaRegionPercent']),
      examGlobalMode: parseMode(json['examGlobalMode']),
      examGlobalValue: parseNum(json['examGlobalValue']),
      overrides: parsedOverrides,
      adminEmails: admins.toList(),
      updatedAt:
          DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
    );
  }
}

/// Service that synchronizes admin pricing rules & admin emails across
/// Supabase (`public.platform_settings`) and local storage so all users'
/// accounts see updated prices immediately.
class PricingService {
  PricingService._();

  static const String _storageKey = 'resolva_platform_pricing_v1';
  static bool _platformSettingsAvailable = true;

  static final Rx<PlatformPricingConfig> config =
      PlatformPricingConfig.defaults().obs;

  static final List<void Function(PlatformPricingConfig)> _listeners = [];

  static void addListener(void Function(PlatformPricingConfig) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener(config.value);
    }
  }

  /// Loads cached pricing config immediately (0ms) and refreshes from Supabase in background.
  static Future<PlatformPricingConfig> initialize() async {
    // 1. Instant local cache load
    try {
      final cached = PaystackService.getCachedJson(_storageKey);
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          config.value = PlatformPricingConfig.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          _notifyListeners();
        }
      }
    } catch (_) {}

    // 2. Non-blocking cloud fetch
    unawaited(fetchFromCloud());
    return config.value;
  }

  /// Fetches the latest pricing configuration from Supabase `public.platform_settings`
  /// (or current user metadata fallback).
  static Future<PlatformPricingConfig> fetchFromCloud() async {
    if (!AuthService.isEnabled) return config.value;

    if (_platformSettingsAvailable) {
      try {
        final row = await Supabase.instance.client
            .from('platform_settings')
            .select('value, updated_at')
            .eq('key', 'pricing_config')
            .maybeSingle()
            .timeout(const Duration(seconds: 4));

        if (row != null && row['value'] is Map) {
          final loaded = PlatformPricingConfig.fromJson(
            Map<String, dynamic>.from(row['value'] as Map),
          );
          config.value = loaded;
          PaystackService.setCachedJson(
            _storageKey,
            jsonEncode(loaded.toJson()),
          );
          _notifyListeners();
          return loaded;
        }
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST205' || e.code == '42P01') {
          _platformSettingsAvailable = false;
        }
      } catch (_) {}
    }

    // Check user_metadata fallback if signed in
    try {
      final meta = AuthService.getCurrentUserMetadata();
      final metaConfig = meta['resolva_pricing_config'];
      if (metaConfig is Map) {
        final loaded = PlatformPricingConfig.fromJson(
          Map<String, dynamic>.from(metaConfig),
        );
        if (loaded.updatedAt.isAfter(config.value.updatedAt)) {
          config.value = loaded;
          PaystackService.setCachedJson(
            _storageKey,
            jsonEncode(loaded.toJson()),
          );
          _notifyListeners();
        }
      }
    } catch (_) {}

    return config.value;
  }

  /// Saves updated pricing configuration and broadcasts to all controllers & Supabase.
  static Future<void> saveConfig(PlatformPricingConfig newConfig) async {
    final stamped = newConfig.copyWith(updatedAt: DateTime.now());
    config.value = stamped;

    // 1. Save to localStorage immediately
    try {
      PaystackService.setCachedJson(_storageKey, jsonEncode(stamped.toJson()));
    } catch (_) {}

    // 2. Notify all active controllers immediately (0ms UI update)
    _notifyListeners();

    // 3. Persist to Supabase in background
    if (!AuthService.isEnabled) return;

    unawaited(() async {
      try {
        await Supabase.instance.client.rpc(
          'admin_save_platform_setting',
          params: {
            'p_key': 'pricing_config',
            'p_value': stamped.toJson(),
          },
        ).timeout(const Duration(seconds: 5));
        _platformSettingsAvailable = true;
      } catch (_) {}

      try {
        if (AuthService.currentUser != null) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'resolva_pricing_config': stamped.toJson(),
              },
            ),
          );
        }
      } catch (_) {}
    }());
  }

  /// Applies the current `PlatformPricingConfig` to a `SocialService`, preserving its
  /// original provider base rate so repeated rule updates never compound.
  static SocialService applyToSocialService(
    SocialService service,
    double baseDisplayAmount,
  ) {
    final newDisplayAmount =
        config.value.effectiveSocialRate(service, baseDisplayAmount);
    final isPerUnit = service.pricingModel == 'per_unit' ||
        service.displayUnit == 'per unit';
    final newPricePerUnit =
        isPerUnit ? newDisplayAmount : (newDisplayAmount / 1000.0);

    return service.copyWithPricing(
      displayAmount: newDisplayAmount,
      pricePerUnit: newPricePerUnit,
    );
  }

  /// Applies the current `PlatformPricingConfig` to an `ExamProduct`.
  static ExamProduct applyToExamProduct(
    ExamProduct product,
    double basePrice,
  ) {
    final newPrice = config.value.effectiveExamPrice(product, basePrice);
    return product.copyWithPrice(newPrice);
  }
}
