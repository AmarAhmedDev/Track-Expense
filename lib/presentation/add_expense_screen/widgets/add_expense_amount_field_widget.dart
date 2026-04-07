import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

/// Large prominent amount input field.
/// Displays currency symbol prominently with large text for easy entry.
class AddExpenseAmountFieldWidget extends StatefulWidget {
  final TextEditingController controller;

  const AddExpenseAmountFieldWidget({super.key, required this.controller});

  @override
  State<AddExpenseAmountFieldWidget> createState() =>
      _AddExpenseAmountFieldWidgetState();
}

class _AddExpenseAmountFieldWidgetState
    extends State<AddExpenseAmountFieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _borderAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: widget.controller.text,
          validator: (value) {
            final text = widget.controller.text;
            if (text.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final parsed = double.tryParse(text);
            if (parsed == null || parsed <= 0) {
              return 'Enter a valid amount greater than 0';
            }
            return null;
          },
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _borderAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceVariantDark
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: field.hasError
                              ? AppTheme.error
                              : Color.lerp(
                                  isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
                                  AppTheme.primary,
                                  _borderAnimation.value,
                                )!,
                          width: field.hasError ? 1.5 : (1 + _borderAnimation.value),
                        ),
                        boxShadow: _isFocused && !field.hasError
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryMuted,
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    children: [
                      // Currency symbol
                      Container(
                        width: 60,
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            SettingsService.instance.currentSymbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      // Amount input
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          onChanged: field.didChange,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: theme.colorScheme.outline,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
