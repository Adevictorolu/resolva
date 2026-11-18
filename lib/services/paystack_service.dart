import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/config/paystack_config.dart';
import 'paystack_bridge_stub.dart'
    if (dart.library.js_interop) 'paystack_bridge_web.dart';

/// Result of verifying a Paystack transaction via `GET /transaction/verify/:reference`.
class PaystackVerificationResult {
  final bool isSuccess;
  final bool cancelled;
  final String reference;
  final double amountNaira;
  final String channel;
  final String currency;
  final String gatewayResponse;
  final DateTime paidAt;
  final String message;
  final Map<String, dynamic> rawData;

  const PaystackVerificationResult({
    required this.isSuccess,
    this.cancelled = false,
    required this.reference,
    required this.amountNaira,
    required this.channel,
    this.currency = 'NGN',
    this.gatewayResponse = '',
    required this.paidAt,
    required this.message,
    this.rawData = const {},
  });

  factory PaystackVerificationResult.cancelled(String ref) =>
      PaystackVerificationResult(
        isSuccess: false,
        cancelled: true,
        reference: ref,
        amountNaira: 0,
        channel: '',
        paidAt: DateTime.now(),
        message: 'Payment checkout was closed before completion.',
      );

  factory PaystackVerificationResult.failure(String ref, String errorMessage) =>
      PaystackVerificationResult(
        isSuccess: false,
        cancelled: false,
        reference: ref,
        amountNaira: 0,
        channel: '',
        paidAt: DateTime.now(),
        message: errorMessage,
      );
}

/// Service implementing the official Paystack REST API (`https://paystack.com/docs/api/`)
/// and Paystack Inline Checkout popup for RESOLVA Wallet Funding.
class PaystackService {
  PaystackService._();

  static final Random _rng = Random();

  /// Generates a unique Paystack transaction reference.
  static String generateReference() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = 100000 + _rng.nextInt(900000);
    return 'RSV-PSK-$ts-$rand';
  }

  /// Maps UI payment channel selection to Paystack API `channels` values.
  /// Official Paystack channels: `['card', 'bank', 'ussd', 'qr', 'mobile_money', 'bank_transfer']`.
  static List<String> mapChannels(String selectedMethod) {
    return switch (selectedMethod) {
      'Debit Card' => ['card'],
      'Bank Transfer' => ['bank_transfer', 'bank'],
      'USSD' => ['ussd'],
      _ => ['card', 'bank_transfer', 'bank', 'ussd', 'qr', 'mobile_money'],
    };
  }

  /// Formats Paystack channel code into a clean user-facing label.
  static String formatChannelLabel(String channel, {String fallback = 'Paystack'}) {
    return switch (channel.toLowerCase()) {
      'card' => 'Paystack (Debit Card)',
      'bank_transfer' || 'dedicated_nuban' => 'Paystack (Bank Transfer)',
      'bank' => 'Paystack (Bank)',
      'ussd' => 'Paystack (USSD)',
      'qr' => 'Paystack (QR)',
      'mobile_money' => 'Paystack (Mobile Money)',
      _ => fallback.startsWith('Paystack') ? fallback : 'Paystack ($fallback)',
    };
  }

  /// Calls `POST https://api.paystack.co/transaction/initialize`
  /// Docs: https://paystack.com/docs/api/transaction/#initialize
  static Future<Map<String, dynamic>?> initializeTransaction({
    required String email,
    required double amountNaira,
    required String reference,
    required List<String> channels,
    String? fullName,
    String? userId,
    String? callbackUrl,
  }) async {
    final amountKobo = (amountNaira * 100).round();
    final uri = Uri.parse('${PaystackConfig.baseUrl}/transaction/initialize');

    final body = <String, dynamic>{
      'email': email.trim(),
      'amount': amountKobo.toString(),
      'currency': 'NGN',
      'reference': reference,
      'channels': channels,
      if (callbackUrl != null && callbackUrl.isNotEmpty)
        'callback_url': callbackUrl,
      'metadata': {
        'user_id': userId ?? '',
        'full_name': fullName ?? '',
        'purpose': 'RESOLVA Wallet Funding',
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${PaystackConfig.secretKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && decoded['status'] == true) {
      return decoded['data'] as Map<String, dynamic>?;
    }
    throw Exception(decoded['message'] ?? 'Could not initialize Paystack transaction.');
  }

  /// Calls `GET https://api.paystack.co/transaction/verify/:reference`
  /// Docs: https://paystack.com/docs/api/transaction/#verify
  static Future<PaystackVerificationResult> verifyTransaction(
    String reference,
  ) async {
    final cleanRef = reference.trim();
    if (cleanRef.isEmpty) {
      return PaystackVerificationResult.failure(
        reference,
        'Transaction reference cannot be empty.',
      );
    }

    final uri = Uri.parse(
      '${PaystackConfig.baseUrl}/transaction/verify/${Uri.encodeComponent(cleanRef)}',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${PaystackConfig.secretKey}',
          'Content-Type': 'application/json',
        },
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || decoded['status'] != true) {
        return PaystackVerificationResult.failure(
          cleanRef,
          (decoded['message'] ?? 'Unable to verify transaction with Paystack.').toString(),
        );
      }

      final data = (decoded['data'] as Map<String, dynamic>?) ?? const {};
      final txStatus = (data['status'] ?? '').toString().toLowerCase();
      final amountKobo = (data['amount'] as num?) ?? 0;
      final amountNaira = amountKobo / 100.0;
      final channel = (data['channel'] ?? 'paystack').toString();
      final currency = (data['currency'] ?? 'NGN').toString();
      final gatewayResponse = (data['gateway_response'] ?? '').toString();
      final paidAtStr = (data['paid_at'] ?? data['created_at'] ?? '').toString();
      final paidAt = DateTime.tryParse(paidAtStr) ?? DateTime.now();

      if (txStatus == 'success' && amountNaira > 0) {
        return PaystackVerificationResult(
          isSuccess: true,
          reference: (data['reference'] ?? cleanRef).toString(),
          amountNaira: amountNaira,
          channel: channel,
          currency: currency,
          gatewayResponse: gatewayResponse,
          paidAt: paidAt,
          message: 'Payment verified successfully via Paystack.',
          rawData: data,
        );
      }

      return PaystackVerificationResult.failure(
        cleanRef,
        'Transaction status is "$txStatus" (${gatewayResponse.isNotEmpty ? gatewayResponse : "not yet confirmed"}).',
      );
    } catch (e) {
      return PaystackVerificationResult.failure(
        cleanRef,
        'Error verifying transaction with Paystack: $e',
      );
    }
  }

  /// Opens the Paystack Inline Checkout Modal for the user, waits for payment
  /// completion, and immediately verifies the payment via `GET /transaction/verify/:reference`.
  static Future<PaystackVerificationResult> checkoutAndVerify({
    required String email,
    required double amountNaira,
    required String selectedMethod,
    required String fullName,
    required String userId,
  }) async {
    final reference = generateReference();
    final amountKobo = (amountNaira * 100).round();
    final channels = mapChannels(selectedMethod);
    final customerEmail =
        email.trim().isNotEmpty ? email.trim() : 'customer@resolva.ng';

    String? completedRef;
    try {
      completedRef = await openPaystackInlinePopup(
        publicKey: PaystackConfig.publicKey,
        email: customerEmail,
        amountKobo: amountKobo,
        reference: reference,
        channels: channels,
        fullName: fullName,
        userId: userId,
      );
    } catch (e) {
      return PaystackVerificationResult.failure(
        reference,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }

    if (completedRef == null || completedRef.isEmpty) {
      return PaystackVerificationResult.cancelled(reference);
    }

    // Verify with Paystack API (/transaction/verify/:reference).
    // Retry up to 3 times if Paystack settlement is still propagating.
    PaystackVerificationResult lastResult =
        await verifyTransaction(completedRef);
    for (int attempt = 1;
        attempt < 3 && !lastResult.isSuccess;
        attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      lastResult = await verifyTransaction(completedRef);
    }
    return lastResult;
  }

  /// Browser localStorage helpers for instant offline/refresh cache.
  static String? getCachedJson(String key) => readLocalStorage(key);
  static void setCachedJson(String key, String value) =>
      writeLocalStorage(key, value);
}
