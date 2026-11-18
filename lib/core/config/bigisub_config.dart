/// Bigisub API configuration for RESOLVA (Social Media Boosting / Marketing Hub
/// & Other Services — Examination E-Pins / Education).
///
/// Documentation: https://rif.africa/technotronics/api/bigisub
/// Base URL: https://api.bigisub.ng
///
/// Security Note:
/// - `BIGISUB_API_TOKEN` is stored exclusively in Supabase Secrets / Vault
///   (`vault.decrypted_secrets` / `bigisub-proxy` Edge Function / `bigisub_api_proxy` RPC)
///   and is never committed to GitHub.
class BigisubConfig {
  BigisubConfig._();

  static const String baseUrl = 'https://api.bigisub.ng';

  static const String _envApiToken =
      String.fromEnvironment('BIGISUB_API_TOKEN');

  static const String _envPin =
      String.fromEnvironment('BIGISUB_PIN', defaultValue: '1234');

  static String _runtimeToken = '';

  /// Allows an authenticated session to hydrate the token from Supabase Vault/Admin settings if needed.
  static void setRuntimeToken(String token) {
    _runtimeToken = token.trim();
  }

  /// Optional local token if provided at runtime; production calls route through Supabase Proxy.
  static String get apiToken =>
      _runtimeToken.isNotEmpty ? _runtimeToken : _envApiToken;

  /// Default 4-digit PIN for Bigisub Education Result Checker purchases if user PIN is 6 digits.
  static String get defaultPin => _envPin;

  /// Authorization header map when calling Bigisub directly.
  static Map<String, String> get headers => {
        if (apiToken.isNotEmpty) 'Authorization': 'Token $apiToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static bool get hasDirectToken => apiToken.isNotEmpty;
}
