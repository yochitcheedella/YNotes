import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../auth/auth_state.dart';
import '../core/utils/app_logger.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange.map((data) {
    if (data.session != null) {
      return AuthState.authenticated();
    } else {
      return AuthState.unauthenticated();
    }
  });

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      AppLogger.error("Login failed", exception: e);
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password, String name) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        options: OtpOptions(
          data: {
            'name': name,
          },
        ),
      );
      return response.user;
    } catch (e) {
      AppLogger.error("Signup failed", exception: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      AppLogger.error("Signout failed", exception: e);
      rethrow;
    }
  }

  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response != null) {
        return UserProfile.fromJson(response);
      }
    } catch (e) {
      AppLogger.error("Failed to fetch user profile", exception: e);
    }
    return null;
  }
}
