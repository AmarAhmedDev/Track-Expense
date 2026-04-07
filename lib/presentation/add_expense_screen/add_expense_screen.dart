import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../database/database_helper.dart';
import '../../models/transaction_model.dart';
import './widgets/add_expense_amount_field_widget.dart';
import './widgets/add_expense_category_grid_widget.dart';
import './widgets/add_expense_type_toggle_widget.dart';

/// Add Expense Screen — full transaction entry form.
/// Supports income/expense toggle, category grid, amount input, date picker, note.
/// Saves to SQLite and returns true to caller for home screen refresh.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod provider for production
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';
  String _selectedCategoryIcon = 'restaurant';
  String _selectedCategoryColor = '#F97316';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonScale;
  late AnimationController _formEntranceController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  @override
  void initState() {
    super.initState();
    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _saveButtonController,
        curve: Curves.easeOutCubic,
      ),
    );

    _formEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formEntranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _formEntranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _formEntranceController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _saveButtonController.dispose();
    _formEntranceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primary), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    _saveButtonController.forward().then(
      (_) => _saveButtonController.reverse(),
    );

    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        title: _selectedType == TransactionType.income 
            ? 'Income' 
            : _titleController.text.trim(),
        amount: amount,
        category: _selectedType == TransactionType.income 
            ? 'Income' 
            : _selectedCategory,
        categoryIcon: _selectedType == TransactionType.income 
            ? 'account_balance_wallet' 
            : _selectedCategoryIcon,
        categoryColor: _selectedType == TransactionType.income 
            ? '#10B981' 
            : _selectedCategoryColor,
        date: _selectedType == TransactionType.income 
            ? DateTime.now() 
            : _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        type: _selectedType,
      );

      await DatabaseHelper.instance.insertTransaction(transaction);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedType == TransactionType.expense ? "Expense" : "Income"} saved successfully!',
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true → triggers home refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't save transaction. Please try again."),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Gradient AppBar
          _buildGradientAppBar(context),
          // Form body
          Expanded(
            child: FadeTransition(
              opacity: _formFadeAnimation,
              child: SlideTransition(
                position: _formSlideAnimation,
                child: isTablet
                    ? _buildTabletForm(context, isDark)
                    : _buildPhoneForm(context, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  _selectedType == TransactionType.expense
                      ? 'Add Expense'
                      : 'Add Income',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Type toggle (Income / Expense)
            AddExpenseTypeToggleWidget(
              selectedType: _selectedType,
              onTypeChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 20),
            // Amount field
            AddExpenseAmountFieldWidget(controller: _amountController),
            if (_selectedType == TransactionType.expense) ...[
              const SizedBox(height: 20),
              // Title field
              _buildTitleField(context),
              const SizedBox(height: 20),
              // Category grid
              AddExpenseCategoryGridWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: (name, icon, color) {
                  setState(() {
                    _selectedCategory = name;
                    _selectedCategoryIcon = icon;
                    _selectedCategoryColor = color;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Date picker
              _buildDateField(context, isDark),
            ],
            const SizedBox(height: 20),
            // Note field
            _buildNoteField(context),
            const SizedBox(height: 32),
            // Save button
            _buildSaveButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AddExpenseTypeToggleWidget(
                  selectedType: _selectedType,
                  onTypeChanged: (type) => setState(() => _selectedType = type),
                ),
                const SizedBox(height: 20),
                AddExpenseAmountFieldWidget(controller: _amountController),
                if (_selectedType == TransactionType.expense) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTitleField(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateField(context, isDark)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AddExpenseCategoryGridWidget(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (name, icon, color) {
                      setState(() {
                        _selectedCategory = name;
                        _selectedCategoryIcon = icon;
                        _selectedCategoryColor = color;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 20),
                _buildNoteField(context),
                const SizedBox(height: 32),
                _buildSaveButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Title',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. Coffee at Starbucks',
            hintStyle: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.title_rounded,
              color: theme.colorScheme.outline,
              size: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryMuted,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceVariantDark
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dateFormat.format(_selectedDate),
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Add a note about this transaction...',
            hintStyle: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 14,
            ),
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(
                Icons.notes_rounded,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ScaleTransition(
      scale: _saveButtonScale,
      child: GestureDetector(
        onTapDown: (_) => _saveButtonController.forward(),
        onTapUp: (_) {
          _saveButtonController.reverse();
          _saveTransaction();
        },
        onTapCancel: () => _saveButtonController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? const LinearGradient(
                    colors: [Color(0xFF94A3B8), Color(0xFF94A3B8)],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(89),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedType == TransactionType.expense
                            ? 'Save Expense'
                            : 'Save Income',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
