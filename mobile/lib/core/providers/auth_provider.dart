import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final String? userEmail;
  final String? accessToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userEmail,
    this.accessToken,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? accessToken,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        userEmail: userEmail ?? this.userEmail,
        accessToken: accessToken ?? this.accessToken,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Auth notifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadStoredAuth();
  }

  final _storage = const FlutterSecureStorage();
  final _api = ApiClient.instance;

  Future<void> _loadStoredAuth() async {
    final token = await _storage.read(key: 'access_token');
    final email = await _storage.read(key: 'user_email');
    if (token != null && email != null) {
      state = state.copyWith(
        isAuthenticated: true,
        accessToken: token,
        userEmail: email,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.post(
        Endpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = resp.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final userEmail = (data['user'] as Map<String, dynamic>)['email'] as String;

      await _storage.write(key: 'access_token', value: token);
      await _storage.write(key: 'user_email', value: userEmail);

      state = state.copyWith(
        isAuthenticated: true,
        accessToken: token,
        userEmail: userEmail,
        isLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.post(
        Endpoints.register,
        data: {'email': email, 'password': password},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(Endpoints.logout);
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
