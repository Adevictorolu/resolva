import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('resolvaOpenPaystack')
external void _resolvaOpenPaystack(
  JSString publicKey,
  JSString email,
  JSNumber amountKobo,
  JSString reference,
  JSString channelsCsv,
  JSString fullName,
  JSString userId,
  JSFunction onSuccess,
  JSFunction onCancel,
  JSFunction onError,
);

/// Opens the official Paystack Inline Checkout popup on Flutter Web.
/// Returns the completed Paystack transaction `reference`, or `null` if cancelled.
Future<String?> openPaystackInlinePopup({
  required String publicKey,
  required String email,
  required int amountKobo,
  required String reference,
  required List<String> channels,
  required String fullName,
  required String userId,
}) {
  final completer = Completer<String?>();

  void handleSuccess(JSString ref) {
    if (!completer.isCompleted) {
      completer.complete(ref.toDart);
    }
  }

  void handleCancel() {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  void handleError(JSString message) {
    if (!completer.isCompleted) {
      completer.completeError(Exception(message.toDart));
    }
  }

  _resolvaOpenPaystack(
    publicKey.toJS,
    email.toJS,
    amountKobo.toJS,
    reference.toJS,
    channels.join(',').toJS,
    fullName.toJS,
    userId.toJS,
    handleSuccess.toJS,
    handleCancel.toJS,
    handleError.toJS,
  );

  return completer.future;
}

String? readLocalStorage(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void writeLocalStorage(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}
