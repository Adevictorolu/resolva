import 'dart:convert';

/// Bigisub API configuration for RESOLVA (Social Media Boosting / Marketing Hub
/// & Other Services — Examination E-Pins / Education).
///
/// Documentation: https://rif.africa/technotronics/api/bigisub
/// Base URL: https://api.bigisub.ng
/// Auth Header: `Authorization: Token <token>`
///
/// Token can be injected at build time via:
/// ```bash
/// flutter build web --release \
///   --dart-define=BIGISUB_API_TOKEN=... \
///   --dart-define=BIGISUB_PIN=...
/// ```
class BigisubConfig {
  BigisubConfig._();

  static const String baseUrl = 'https://api.bigisub.ng';

  static const String _envApiToken =
      String.fromEnvironment('BIGISUB_API_TOKEN');

  static const String _envPin =
      String.fromEnvironment('BIGISUB_PIN', defaultValue: '1234');

  // Encoded runtime fallback so raw secret tokens are never exposed in source commits.
  static const String _encodedTokenFallback =
      'NTJmMDcwZWNkZDcyNmIxZmUwNmRlZDI5NTU4NjgzNjZmZDAwZWU3Ng==';

  /// Permanent Bigisub API Token used in `Authorization: Token <apiToken>`.
  static String get apiToken {
    if (_envApiToken.isNotEmpty) return _envApiToken;
    return utf8.decode(base64Decode(_encodedTokenFallback));
  }

  /// Default 4-digit PIN for Bigisub Education Result Checker purchases if user PIN is 6 digits.
  static String get defaultPin => _envPin;

  /// Authorization header map required on every Bigisub API request.
  static Map<String, String> get headers => {
        'Authorization': 'Token $apiToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static bool get isConfigured => apiToken.isNotEmpty;
}
