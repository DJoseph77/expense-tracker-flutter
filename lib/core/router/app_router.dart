import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../../features/transactions/data/models/transaction_type.dart';
import '../../features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';

/// Class to adapt Riverpod StateNotifier to a Listenable for GoRouter
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final status = authState.status;

      final isChecking =
          status == AuthStatus.checkingSession || status == AuthStatus.initial;
      final isAuthenticated = status == AuthStatus.authenticated;

      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';

      // 1. Still verifying stored token session -> show splash
      if (isChecking) {
        return isSplash ? null : '/splash';
      }

      // 2. If finished checking and still on splash -> redirect appropriately
      if (isSplash) {
        return isAuthenticated ? '/home' : '/login';
      }

      // 3. Unauthenticated user trying to access protected routes -> send to /login
      if (!isAuthenticated && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // 4. Authenticated user trying to access /login or /register -> send to /home
      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final initialEmail = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: initialEmail);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          TransactionType? initialType;
          if (typeParam != null) {
            try {
              initialType = TransactionType.fromJson(typeParam);
            } catch (_) {}
          }
          initialType ??= state.extra as TransactionType?;
          return AddEditTransactionScreen(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return AddEditTransactionScreen(initialTransaction: transaction);
        },
      ),
    ],
  );
});
