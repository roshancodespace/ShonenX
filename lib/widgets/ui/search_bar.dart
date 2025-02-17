import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Searchbar extends StatefulWidget {
  final TextEditingController controller;
  final Function() onSearch;
  final Function()? onClear;
  final bool isLoading;

  const Searchbar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  Animation<Color?>? _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _focusNode.addListener(() {
      setState(() {}); // Trigger rebuild on focus change.
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Initialize inherited dependencies here.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: theme.colorScheme.primary,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    await widget.onSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.isLoading
                  ? (_borderColorAnimation?.value ?? Colors.transparent)
                  : (_focusNode.hasFocus
                      ? theme.colorScheme.primary
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
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Iconsax.search_normal,
                      size: 30,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.text,
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onEditingComplete: _handleSearch,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "Search Anime...",
                    fillColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty &&
                  !widget.isLoading &&
                  widget.onClear != null)
                IconButton(
                  onPressed: widget.onClear,
                  icon: Icon(
                    Iconsax.close_circle,
                    size: 24,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
