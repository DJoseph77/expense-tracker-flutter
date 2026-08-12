import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_response.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  checkingSession,
  unauthenticated,
  authenticating,
  authenticated,
  failure,
}

@immutable
class AuthState {
  final AuthStatus status;
  final UserResponse? user;
  final String? errorMessage;
  final String? registeredEmail;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.registeredEmail,
  });

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      errorMessage = null,
      registeredEmail = null;

  AuthState copyWith({
    AuthStatus? status,
    UserResponse? user,
    String? errorMessage,
    String? registeredEmail,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      registeredEmail: registeredEmail ?? this.registeredEmail,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  final notifier = AuthNotifier(repository: repository);

  // Register unauthorized (401) callback handler with Dio
  ref.read(onUnauthorizedHandlerProvider.notifier).state = (message) {
    notifier.handleUnauthorized(message);
  };

  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier({required AuthRepository repository})
    : _repository = repository,
      super(const AuthState.initial()) {
    checkSession();
  }

  /// Checks for stored token and user profile at startup
  Future<void> checkSession() async {
    state = state.copyWith(
      status: AuthStatus.checkingSession,
      clearError: true,
    );

    try {
      final hasToken = await _repository.hasStoredToken();
      if (hasToken) {
        final user = await _repository.readStoredUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  /// Executes login (POST /api/auth/login -> 200 OK)
  Future<bool> login(String email, String password) async {
    if (state.status == AuthStatus.authenticating) return false;

    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    try {
      final authResponse = await _repository.login(
        LoginRequest(email: email.trim(), password: password),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred during login.',
      );
      return false;
    }
  }

  /// Executes registration (POST /api/auth/register -> 201 Created)
  /// Note: Registration does NOT authenticate the user.
  Future<UserResponse?> register(
    String name,
    String email,
    String password,
  ) async {
    if (state.status == AuthStatus.authenticating) return null;

    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    try {
      final userResponse = await _repository.register(
        RegisterRequest(
          name: name.trim(),
          email: email.trim(),
          password: password,
        ),
      );

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        registeredEmail: userResponse.email,
        clearError: true,
      );
      return userResponse;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred during registration.',
      );
      return null;
    }
  }

  /// Logs out user and clears JWT token & profile from secure storage
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Handles 401 Unauthorized signal from JWT Interceptor
  void handleUnauthorized(String message) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: message,
    );
  }
}
