/// Paystack Live Payment Gateway configuration for RESOLVA.
///
/// Documentation: https://paystack.com/docs/api/
///
/// Security Note:
/// - Only the publishable key (`pk_live_...`) is used by the client-side
///   Paystack Inline JS popup.
/// - `PAYSTACK_SECRET_KEY` is stored exclusively in Supabase Secrets / Vault
///   and never committed to GitHub or bundled into the client web build.
class PaystackConfig {
  PaystackConfig._();

  static const String baseUrl = 'https://api.paystack.co';

  /// Paystack Live Public Key (safe for Paystack Inline JS & client checkout).
  static const String publicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_live_58d1473922bf544d0a24c1ffed660b6cb9a0c0e4',
  );

  /// Optional local development override via `--dart-define=PAYSTACK_SECRET_KEY=...`.
  /// In production, verification runs server-side via Supabase Secrets.
  static const String secretKey =
      String.fromEnvironment('PAYSTACK_SECRET_KEY');

  static bool get isConfigured => publicKey.isNotEmpty;
}
