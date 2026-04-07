
import '../../../core/app_export.dart';

/// Inline search bar — NOT the default SearchDelegate.
/// Custom animated search field with clear button.
class TransactionHistorySearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;

  const TransactionHistorySearchBarWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<TransactionHistorySearchBarWidget> createState() =>
      _TransactionHistorySearchBarWidgetState();
}

class _TransactionHistorySearchBarWidgetState
    extends State<TransactionHistorySearchBarWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  late AnimationController _focusAnimController;
  late Animation<double> _focusBorderAnimation;

  @override
  void initState() {
    super.initState();
    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusBorderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusAnimController, curve: Curves.easeOutCubic),
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _focusAnimController.forward();
      } else {
        _focusAnimController.reverse();
      }
    });
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _focusAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _focusBorderAnimation,
      builder: (context, child) {
        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceVariantDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
                AppTheme.primary,
                _focusBorderAnimation.value,
              )!,
              width: 1 + _focusBorderAnimation.value * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppTheme.primaryMuted
                    : Colors.black.withAlpha(10),
                blurRadius: _isFocused ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 14,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFocused ? Icons.search_rounded : Icons.search_outlined,
              key: ValueKey(_isFocused),
              size: 20,
              color: _isFocused
                  ? AppTheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                    _focusNode.unfocus();
                  },
                  icon: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
