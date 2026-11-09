/// Supabase connection settings for RESOLVA.
///
/// Values are injected at build time so no keys live in source control:
///
/// ```bash
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon-public-key>
/// ```
///
/// The GitHub Pages workflow reads the same values from the repository
/// variables `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
///
/// When either value is missing the app falls back to the original
/// frontend-only demo mode (mock users, demo PIN 123456).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jykwnzabsrbxcvaiykih.supabase.co',
  );
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Optional override for the OAuth redirect URL (defaults to the current page URL on web).
  static const String redirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
