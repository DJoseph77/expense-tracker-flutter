import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${user?.name ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text('Role: ${user?.role ?? 'USER'}'),
                backgroundColor: Colors.teal.shade50,
              ),
              const SizedBox(height: 32),

              // Categories Action Button
              ElevatedButton.icon(
                onPressed: () => context.push('/categories'),
                icon: const Icon(Icons.category_outlined),
                label: const Text('Categories'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[300]!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
