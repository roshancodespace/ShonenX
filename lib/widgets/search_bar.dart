import 'package:flutter/material.dart';

class Searchbar extends StatelessWidget {
  final TextEditingController controller;
  final Function onSearch;

  const Searchbar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeContext = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: themeContext.colorScheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.text,
              controller: controller,
              onEditingComplete: () {
                FocusScope.of(context).unfocus(); // Unfocus after submitting
                onSearch();
              },
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
  }
}
