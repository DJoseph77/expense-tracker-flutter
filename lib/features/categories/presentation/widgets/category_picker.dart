import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../providers/category_provider.dart';

class CategoryPicker extends ConsumerWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;

  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryStateProvider);

    if (categoryState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final categories = categoryState.categories;

    return DropdownButtonFormField<Category>(
      initialValue:
          selectedCategory != null &&
              categories.any((c) => c.id == selectedCategory!.id)
          ? categories.firstWhere((c) => c.id == selectedCategory!.id)
          : null,
      decoration: const InputDecoration(
        labelText: 'Select Category',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<Category>(
          value: category,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}
