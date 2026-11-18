import 'dart:async';

/// Stub implementation for non-web platforms / widget tests.
Future<String?> openPaystackInlinePopup({
  required String publicKey,
  required String email,
  required int amountKobo,
  required String reference,
  required List<String> channels,
  required String fullName,
  required String userId,
}) async {
  // In non-web tests, return the reference immediately.
  return reference;
}

String? readLocalStorage(String key) => null;

void writeLocalStorage(String key, String value) {}
