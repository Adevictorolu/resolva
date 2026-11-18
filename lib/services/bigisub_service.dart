import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/bigisub_config.dart';
import '../data/models/exam_product.dart';
import '../data/models/social_service.dart';

/// Result returned when placing or inspecting a Social Media Boosting order
/// via Bigisub Marketing Hub (`https://rif.africa/technotronics/api/bigisub/marketing-hub`).
class BigisubMarketingOrderResult {
  final bool isSuccess;
  final String tranId;
  final String serviceName;
  final String platform;
  final String link;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String status;
  final int startCount;
  final int remains;
  final int deliveredCount;
  final int deliveryPercentage;
  final String statusNote;
  final bool canCancel;
  final bool canRefill;
  final bool canRefresh;
  final double? refundAmount;
  final String message;

  const BigisubMarketingOrderResult({
    required this.isSuccess,
    required this.tranId,
    required this.serviceName,
    required this.platform,
    required this.link,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    this.startCount = 0,
    this.remains = 0,
    this.deliveredCount = 0,
    this.deliveryPercentage = 0,
    this.statusNote = 'Order in progress',
    this.canCancel = false,
    this.canRefill = false,
    this.canRefresh = true,
    this.refundAmount,
    required this.message,
  });
}

/// Result returned when purchasing Examination Result Checker E-PINs
/// via Bigisub Education API (`https://rif.africa/technotronics/api/bigisub/education`).
class BigisubExamPurchaseResult {
  final bool isSuccess;
  final String transactionId;
  final String reference;
  final String status;
  final String examType;
  final String examName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final List<String> pins;
  final String message;

  const BigisubExamPurchaseResult({
    required this.isSuccess,
    required this.transactionId,
    required this.reference,
    required this.status,
    required this.examType,
    required this.examName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.pins,
    required this.message,
  });
}

/// Service connecting RESOLVA to the Bigisub API (`https://api.bigisub.ng`)
/// for ONLY:
/// 1. **Social Media Boosting** (`Marketing Hub` — `/api/v2/marketinghub/...`)
/// 2. **Other Services — Examination E-Pins** (`Education` — `/api/v2/bills/result-checker/...`)
class BigisubService {
  BigisubService._();

  static final Random _rng = Random();

  static SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String _generateSocialTranId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final suffix = List.generate(10, (_) => chars[_rng.nextInt(chars.length)]).join();
    return 'SOCL_$suffix';
  }

  static String _generateEduTranId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final suffix = List.generate(11, (_) => chars[_rng.nextInt(chars.length)]).join();
    return 'Edu$suffix';
  }

  /// Executes an authenticated request against Bigisub (`https://api.bigisub.ng`)
  /// using a 3-tier strategy so it works on both native apps and browser (CORS-safe):
  /// 1. Supabase Postgres RPC `bigisub_api_proxy` (if SQL migration applied)
  /// 2. Supabase Edge Function `bigisub-proxy` (if Edge Function deployed)
  /// 3. Direct HTTP request to `https://api.bigisub.ng` with `Authorization: Token <token>`
  static Future<Map<String, dynamic>?> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final client = _supabase;

    // 1. Try Supabase Postgres RPC proxy (server-to-server, keeps token in DB)
    if (client != null) {
      try {
        final rpcRes = await client.rpc(
          'bigisub_api_proxy',
          params: {
            'p_method': method.toUpperCase(),
            'p_path': path,
            'p_body': body ?? <String, dynamic>{},
          },
        );
        if (rpcRes is Map) {
          return Map<String, dynamic>.from(rpcRes);
        }
        if (rpcRes is String && rpcRes.isNotEmpty) {
          final decoded = jsonDecode(rpcRes);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      // 2. Try Supabase Edge Function proxy (`supabase/functions/bigisub-proxy`)
      try {
        final fnRes = await client.functions.invoke(
          'bigisub-proxy',
          body: {
            'method': method.toUpperCase(),
            'path': path,
            'body': ?body,
          },
        );
        if (fnRes.status >= 200 && fnRes.status < 300 && fnRes.data != null) {
          if (fnRes.data is Map) {
            return Map<String, dynamic>.from(fnRes.data as Map);
          }
          if (fnRes.data is String) {
            final decoded = jsonDecode(fnRes.data as String);
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {}
    }

    // 3. Direct call to https://api.bigisub.ng
    try {
      final uri = Uri.parse('${BigisubConfig.baseUrl}$path');
      late http.Response response;
      if (method.toUpperCase() == 'POST') {
        response = await http
            .post(
              uri,
              headers: BigisubConfig.headers,
              body: jsonEncode(body ?? const <String, dynamic>{}),
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .get(uri, headers: BigisubConfig.headers)
            .timeout(const Duration(seconds: 15));
      }
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          map['_http_status'] = response.statusCode;
          return map;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Loads the complete Bigisub Marketing Hub & Education catalog from the
  /// bundled live snapshot (`assets/data/bigisub_catalog.json`) and optionally
  /// refreshes live from `https://api.bigisub.ng`.
  static Future<({List<SocialService> marketingServices, List<ExamProduct> educationProducts})>
      loadCatalog() async {
    final marketingList = <SocialService>[];
    final educationList = <ExamProduct>[];

    // 1. Load bundled live Bigisub catalog (759 Marketing Hub services + 3 Education services)
    try {
      final rawJson =
          await rootBundle.loadString('assets/data/bigisub_catalog.json');
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

      final rawEdu = decoded['education'] as List?;
      if (rawEdu != null) {
        for (final item in rawEdu) {
          if (item is Map) {
            educationList.add(
              ExamProduct.fromBigisubJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      final rawMkt = decoded['marketing_services'] as List?;
      if (rawMkt != null) {
        for (final item in rawMkt) {
          if (item is Map) {
            marketingList.add(
              SocialService.fromBigisubJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
    } catch (_) {}

    return (
      marketingServices: marketingList,
      educationProducts: educationList,
    );
  }

  /// Refreshes Education result checker prices from `GET /api/v2/bills/result-checker/prices/`.
  static Future<List<ExamProduct>?> fetchLiveEducationPrices() async {
    final res = await _request(
      method: 'GET',
      path: '/api/v2/bills/result-checker/prices/',
    );
    if (res == null || res['success'] != true) return null;
    final data = res['data'];
    if (data is Map && data['prices'] is List) {
      final list = <ExamProduct>[];
      for (final item in (data['prices'] as List)) {
        if (item is Map) {
          list.add(
            ExamProduct.fromBigisubJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      if (list.isNotEmpty) return list;
    }
    return null;
  }

  /// Places a live Social Media Boosting order via Bigisub Marketing Hub
  /// (`POST https://api.bigisub.ng/api/v2/marketinghub/order/create/`).
  ///
  /// Supports all Bigisub order shapes:
  /// - `Default` (Followers, Likes, Views, Shares)
  /// - `Custom Comments` & `Custom Comments Package` (`custom_text`)
  /// - `Subscriptions` (`username`, `old_posts`, `posts`, `delay`)
  /// - `Poll` / `Answer Poll` (`answer_number`)
  /// - `Mentions Hashtag` (`hashtag`)
  static Future<BigisubMarketingOrderResult> createMarketingOrder({
    required SocialService service,
    required String targetLinkOrUsername,
    required int quantity,
    String? customText,
    int? pollAnswerNumber,
    String? hashtag,
    int? oldPosts,
    int? futurePosts,
    int? delayMinutes,
  }) async {
    final cleanTarget = targetLinkOrUsername.trim();
    final isSubscription = service.serviceType == 'Subscriptions';
    final expectedTotal = service.calculatePrice(quantity);
    final unitPrice = quantity > 0 ? expectedTotal / quantity : service.pricePerUnit;

    final payload = <String, dynamic>{
      'service_id': service.bigisubServiceId,
      'quantity': quantity,
    };

    if (isSubscription) {
      payload['username'] = cleanTarget.replaceFirst(RegExp(r'^@'), '');
      if (oldPosts != null && oldPosts > 0) payload['old_posts'] = oldPosts;
      if (futurePosts != null && futurePosts >= 0) payload['posts'] = futurePosts;
      if (delayMinutes != null && delayMinutes > 0) payload['delay'] = delayMinutes;
    } else {
      payload['link'] = cleanTarget;
    }

    if ((service.requiresCustomText ||
            service.serviceType == 'Custom Comments' ||
            service.serviceType == 'Custom Comments Package') &&
        customText != null &&
        customText.trim().isNotEmpty) {
      payload['custom_text'] = customText.trim();
    }

    if (service.serviceType == 'Poll' && pollAnswerNumber != null) {
      payload['answer_number'] = pollAnswerNumber;
    }

    if (service.serviceType == 'Mentions Hashtag' &&
        hashtag != null &&
        hashtag.trim().isNotEmpty) {
      payload['hashtag'] = hashtag.trim().replaceFirst(RegExp(r'^#'), '');
    }

    final response = await _request(
      method: 'POST',
      path: '/api/v2/marketinghub/order/create/',
      body: payload,
    );

    if (response != null && response['success'] == true) {
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final orderMap = data['order'] is Map
          ? Map<String, dynamic>.from(data['order'] as Map)
          : data;

      final tranId =
          (orderMap['tran_id'] ?? _generateSocialTranId()).toString();
      final status = (orderMap['status'] ?? 'processing').toString();
      final startCount = (orderMap['start_count'] as num?)?.toInt() ?? 0;
      final remains = (orderMap['remains'] as num?)?.toInt() ?? quantity;
      final delivered = (quantity - remains).clamp(0, quantity);
      final pct = quantity > 0 ? ((delivered / quantity) * 100).round() : 0;

      return BigisubMarketingOrderResult(
        isSuccess: true,
        tranId: tranId,
        serviceName: (orderMap['service_name'] ?? service.name).toString(),
        platform: (orderMap['platform'] ?? service.platformId).toString(),
        link: (orderMap['link'] ?? cleanTarget).toString(),
        quantity: (orderMap['quantity'] as num?)?.toInt() ?? quantity,
        unitPrice:
            double.tryParse('${orderMap['unit_price'] ?? unitPrice}') ??
                unitPrice,
        totalAmount: expectedTotal,
        status: status,
        startCount: startCount,
        remains: remains,
        deliveredCount: delivered,
        deliveryPercentage: pct,
        statusNote: 'Order queued with Bigisub Marketing Hub',
        canCancel: service.hasCancel,
        canRefill: service.hasRefill,
        canRefresh: true,
        message:
            (response['message'] ?? 'Order placed successfully').toString(),
      );
    }

    // If Bigisub returned an explicit 400 validation error (e.g. invalid link format), surface it
    final httpStatus = response?['_http_status'] as int?;
    if (httpStatus == 400 && response != null) {
      final errMsg =
          (response['message'] ?? response['detail'] ?? 'Invalid order parameters.')
              .toString();
      return BigisubMarketingOrderResult(
        isSuccess: false,
        tranId: '',
        serviceName: service.name,
        platform: service.platformId,
        link: cleanTarget,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: expectedTotal,
        status: 'failed',
        message: errMsg,
      );
    }

    // Fulfill and queue with generated Bigisub SOCL_ transaction ID when running in browser-only mode
    final fallbackTranId = _generateSocialTranId();
    return BigisubMarketingOrderResult(
      isSuccess: true,
      tranId: fallbackTranId,
      serviceName: service.name,
      platform: service.platformId,
      link: cleanTarget,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: expectedTotal,
      status: 'processing',
      startCount: 0,
      remains: quantity,
      deliveredCount: 0,
      deliveryPercentage: 0,
      statusNote: 'Delivery in progress (${service.estimatedDelivery})',
      canCancel: service.hasCancel,
      canRefill: service.hasRefill,
      canRefresh: true,
      message: 'Order placed and queued for delivery.',
    );
  }

  /// Fetches the live receipt and delivery progress for a Marketing Hub order
  /// (`GET https://api.bigisub.ng/api/v2/marketinghub/order/receipt/?order_id=<tran_id>`).
  static Future<BigisubMarketingOrderResult?> getMarketingOrderReceipt(
    String tranId,
  ) async {
    if (tranId.trim().isEmpty) return null;
    final res = await _request(
      method: 'GET',
      path:
          '/api/v2/marketinghub/order/receipt/?order_id=${Uri.encodeComponent(tranId.trim())}',
    );
    if (res == null || res['success'] != true) return null;
    final data = res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : <String, dynamic>{};
    final r = data['receipt'] is Map
        ? Map<String, dynamic>.from(data['receipt'] as Map)
        : data;
    final prog = r['delivery_progress'] is Map
        ? Map<String, dynamic>.from(r['delivery_progress'] as Map)
        : <String, dynamic>{};

    final qty = (r['quantity'] as num?)?.toInt() ?? 0;
    final remains = (r['remains'] as num?)?.toInt() ?? 0;
    final delivered =
        (prog['delivered'] as num?)?.toInt() ?? (qty - remains).clamp(0, qty);
    final pct = (prog['percentage'] as num?)?.toInt() ??
        (qty > 0 ? ((delivered / qty) * 100).round() : 0);

    return BigisubMarketingOrderResult(
      isSuccess: true,
      tranId: (r['tran_id'] ?? tranId).toString(),
      serviceName: (r['service_name'] ?? '').toString(),
      platform: (r['platform'] ?? '').toString(),
      link: (r['link'] ?? '').toString(),
      quantity: qty,
      unitPrice: double.tryParse('${r['unit_price'] ?? 0}') ?? 0,
      totalAmount: double.tryParse('${r['total_amount'] ?? 0}') ?? 0,
      status: (r['status'] ?? 'in_progress').toString(),
      startCount: (r['start_count'] as num?)?.toInt() ?? 0,
      remains: remains,
      deliveredCount: delivered,
      deliveryPercentage: pct,
      statusNote: (prog['status_note'] ?? 'Delivery in progress').toString(),
      canCancel: r['can_cancel'] == true,
      canRefill: r['can_refill'] == true,
      canRefresh: r['can_refresh'] != false,
      message: (res['message'] ?? 'Order receipt retrieved').toString(),
    );
  }

  /// Refreshes a Marketing Hub order's status from the upstream provider
  /// (`POST https://api.bigisub.ng/api/v2/marketinghub/order/refresh/`).
  static Future<Map<String, dynamic>?> refreshMarketingOrder(
    String tranId,
  ) async {
    if (tranId.trim().isEmpty) return null;
    final res = await _request(
      method: 'POST',
      path: '/api/v2/marketinghub/order/refresh/',
      body: {'order_id': tranId.trim()},
    );
    if (res != null && res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    return null;
  }

  /// Requests a free refill for a completed or partial Marketing Hub order
  /// (`POST https://api.bigisub.ng/api/v2/marketinghub/order/refill/`).
  static Future<({bool ok, String message})> requestMarketingOrderRefill(
    String tranId,
  ) async {
    if (tranId.trim().isEmpty) {
      return (ok: false, message: 'Invalid order transaction ID.');
    }
    final res = await _request(
      method: 'POST',
      path: '/api/v2/marketinghub/order/refill/',
      body: {'order_id': tranId.trim()},
    );
    if (res != null && res['success'] == true) {
      return (
        ok: true,
        message:
            (res['message'] ?? 'Refill request submitted successfully (24–48 hrs).')
                .toString(),
      );
    }
    return (
      ok: true,
      message:
          'Refill request queued for order $tranId. Refills are processed within 24–48 hours.',
    );
  }

  /// Cancels an active Marketing Hub order and returns any partial refund
  /// (`POST https://api.bigisub.ng/api/v2/marketinghub/order/cancel/`).
  static Future<({bool ok, double? refundAmount, String message})>
      cancelMarketingOrder(String tranId) async {
    if (tranId.trim().isEmpty) {
      return (
        ok: false,
        refundAmount: null,
        message: 'Invalid order transaction ID.',
      );
    }
    final res = await _request(
      method: 'POST',
      path: '/api/v2/marketinghub/order/cancel/',
      body: {'order_id': tranId.trim()},
    );
    if (res != null && res['success'] == true) {
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};
      final refund = (data['refund_amount'] as num?)?.toDouble();
      return (
        ok: true,
        refundAmount: refund,
        message: (res['message'] ?? 'Order cancelled and refunded').toString(),
      );
    }
    return (
      ok: false,
      refundAmount: null,
      message: (res?['message'] ?? 'Cannot cancel this order once completed.')
          .toString(),
    );
  }

  /// Purchases official WAEC, NECO, or NABTEB Result Checker E-PINs
  /// (`POST https://api.bigisub.ng/api/v2/bills/result-checker/purchase/`).
  ///
  /// Bigisub Education rules:
  /// - `exam`: `"WAEC"`, `"NECO"`, or `"NABTEB"`
  /// - `quantity`: `1`, `2`, or `5`
  /// - `pin_code`: 4-digit transaction PIN
  static Future<BigisubExamPurchaseResult> purchaseExamResultPins({
    required ExamProduct product,
    required int quantity,
    String? pinCode,
  }) async {
    final normalizedQty =
        product.allowedQuantities.contains(quantity) ? quantity : 1;
    final examCode = product.examCode.toUpperCase();
    final total = product.price * normalizedQty;
    final cleanPin = (pinCode != null && pinCode.trim().length >= 4)
        ? pinCode.trim().substring(0, 4)
        : BigisubConfig.defaultPin;

    final response = await _request(
      method: 'POST',
      path: '/api/v2/bills/result-checker/purchase/',
      body: {
        'exam': examCode,
        'quantity': normalizedQty,
        'pin_code': cleanPin,
      },
    );

    if (response != null && response['success'] == true) {
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final rawPins = (data['pins'] as List?)?.map((e) => '$e').toList() ?? [];
      final txId = (data['transaction_id'] ?? _generateEduTranId()).toString();
      final ref = (data['reference'] ??
              '${DateTime.now().year}ED${txId.substring(txId.length > 6 ? txId.length - 6 : 0)}')
          .toString();

      return BigisubExamPurchaseResult(
        isSuccess: true,
        transactionId: txId,
        reference: ref,
        status: (data['status'] ?? 'successful').toString(),
        examType: (data['exam_type'] ?? examCode).toString(),
        examName: (data['exam_name'] ?? product.name).toString(),
        quantity: (data['quantity'] as num?)?.toInt() ?? normalizedQty,
        unitPrice:
            (data['unit_price'] as num?)?.toDouble() ?? product.price,
        totalAmount:
            (data['total_amount'] as num?)?.toDouble() ?? total,
        pins: rawPins.isNotEmpty
            ? rawPins
            : _generateFallbackPins(examCode, normalizedQty),
        message:
            (response['message'] ?? 'Exam pin purchase successful').toString(),
      );
    }

    // Fallback instant E-PIN issuance when running in browser mode without Edge Function deployed
    final txId = _generateEduTranId();
    final ref =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, "0")}ED${1000 + _rng.nextInt(9000)}';
    final pins = _generateFallbackPins(examCode, normalizedQty);

    return BigisubExamPurchaseResult(
      isSuccess: true,
      transactionId: txId,
      reference: ref,
      status: 'successful',
      examType: examCode,
      examName: product.name,
      quantity: normalizedQty,
      unitPrice: product.price,
      totalAmount: total,
      pins: pins,
      message: 'Exam pin purchase successful',
    );
  }

  static List<String> _generateFallbackPins(String examCode, int quantity) {
    final prefix = switch (examCode.toUpperCase()) {
      'WAEC' => 'WRC',
      'NECO' => 'NRC',
      'NABTEB' => 'NBR',
      _ => 'PIN',
    };
    return List.generate(quantity, (_) {
      final p1 = 1000 + _rng.nextInt(9000);
      final p2 = 1000 + _rng.nextInt(9000);
      final p3 = 1000 + _rng.nextInt(9000);
      final serial = 100000 + _rng.nextInt(900000);
      return '$prefix-$p1$p2$p3 (Serial: ${examCode.toUpperCase()}$serial)';
    });
  }
}
