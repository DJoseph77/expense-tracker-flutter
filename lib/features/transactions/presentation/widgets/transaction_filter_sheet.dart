import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../data/models/transaction_filters.dart';
import '../../data/models/transaction_type.dart';
import '../providers/transaction_provider.dart';

class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  TransactionType? _selectedType;
  Category? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(transactionStateProvider).filters;
    _selectedType = currentFilters.type;
    _startDate = currentFilters.startDate;
    _endDate = currentFilters.endDate;
    _minAmountController = TextEditingController(
      text: currentFilters.minAmount ?? '',
    );
    _maxAmountController = TextEditingController(
      text: currentFilters.maxAmount ?? '',
    );

    if (currentFilters.categoryId != null) {
      _selectedCategory = Category(id: currentFilters.categoryId!, name: '');
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _validationError = null;
      });
    }
  }

  void _apply() async {
    final minTxt = _minAmountController.text.trim();
    final maxTxt = _maxAmountController.text.trim();

    final newFilters = TransactionFilters(
      type: _selectedType,
      categoryId: _selectedCategory?.id,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: minTxt.isEmpty ? null : minTxt,
      maxAmount: maxTxt.isEmpty ? null : maxTxt,
    );

    final error = newFilters.validate();
    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    final success = await ref
        .read(transactionStateProvider.notifier)
        .applyFilters(newFilters);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void _clear() async {
    await ref.read(transactionStateProvider.notifier).clearFilters();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Type Filter
            const Text(
              'Transaction Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Category Filter
            CategoryPicker(
              selectedCategory: _selectedCategory,
              onChanged: (cat) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Range Filters
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _startDate == null
                          ? 'Start Date'
                          : AppDateUtils.formatDateToYmd(_startDate!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _endDate == null
                          ? 'End Date'
                          : AppDateUtils.formatDateToYmd(_endDate!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Range Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min Amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max Amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
