import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category name is required';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext);

                final notifier = ref.read(categoryStateProvider.notifier);
                bool success;

                if (category == null) {
                  success = await notifier.createCategory(nameController.text);
                } else {
                  success = await notifier.updateCategory(
                    category.id,
                    nameController.text,
                  );
                }

                if (!success && context.mounted) {
                  final err = ref.read(categoryStateProvider).mutationError;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(category == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ref
                    .read(categoryStateProvider.notifier)
                    .deleteCategory(category.id);

                if (!success && context.mounted) {
                  final err = ref.read(categoryStateProvider).mutationError;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final categoryState = ref.watch(categoryStateProvider);

    final isAdmin = authState.user?.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(categoryStateProvider.notifier).loadCategories();
        },
        child: _buildBody(context, ref, categoryState, isAdmin),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: categoryState.isMutating
                  ? null
                  : () => _showAddEditDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CategoryState categoryState,
    bool isAdmin,
  ) {
    if (categoryState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (categoryState.errorMessage != null &&
        categoryState.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                categoryState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(categoryStateProvider.notifier).loadCategories();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (categoryState.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No categories found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create First Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryState.categories.length,
      itemBuilder: (context, index) {
        final category = categoryState.categories[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.label, color: Colors.white),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: categoryState.isMutating
                            ? null
                            : () => _showAddEditDialog(
                                context,
                                ref,
                                category: category,
                              ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: categoryState.isMutating
                            ? null
                            : () => _confirmDelete(context, ref, category),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}
