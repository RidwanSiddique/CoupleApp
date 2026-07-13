import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<void> sendEmailOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName == null ? null : {'display_name': displayName},
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
