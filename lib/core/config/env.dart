/// Compile-time env vars, passed via `--dart-define`.
///
/// For local Supabase, run `supabase status` to see the URL + anon key,
/// then:
///   flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
///               --dart-define=SUPABASE_ANON_KEY=`local-anon-key`
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => supabaseAnonKey.isNotEmpty;
}
