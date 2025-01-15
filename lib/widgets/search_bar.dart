import 'package:flutter/material.dart';

class Searchbar extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSearch; // Async function for search
  final bool isLoading;

  const Searchbar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Defer initialization of the border color animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final theme = Theme.of(context);
      _borderColorAnimation = ColorTween(
        begin: Colors.transparent,
        end: theme.colorScheme.primary,
      ).animate(_animationController);

      setState(() {}); // Trigger a rebuild to initialize the animation
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.unfocus(); // Ensure the focus is removed before disposal
    _focusNode.dispose(); // Dispose of the focus node
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    await widget.onSearch(); // Wait for the onSearch function
    widget.controller.clear(); // Clear the search field
    _focusNode.unfocus(); // Ensure the field is unfocused
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeContext = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: themeContext.colorScheme.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.isLoading
                  ? _borderColorAnimation.value ?? Colors.transparent
                  : (_focusNode.hasFocus
                      ? themeContext.colorScheme.primary
                      : Colors.transparent),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: themeContext.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      size: 30,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.text,
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onEditingComplete: _handleSearch,
                  style: themeContext.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: "Search Anime...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
