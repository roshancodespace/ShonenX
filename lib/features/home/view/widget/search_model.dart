import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

void showSearchModal(BuildContext context, String heroTag) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) {
        final theme = Theme.of(context);
        return FadeTransition(
          opacity: animation,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
              Center(
                child: Hero(
                  tag: heroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SearchBar(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        ),
                        leading: Icon(
                          Iconsax.search_normal,
                          color: theme.colorScheme.onSurface,
                        ),
                        trailing: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: theme.colorScheme.primaryContainer,
                              width: 2,
                            ),
                          ),
                        ),
                        hintText: 'Search anime...',
                        hintStyle: WidgetStatePropertyAll(
                          TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.surfaceContainer,
                        ),
                        elevation: const WidgetStatePropertyAll(0),
                        autoFocus: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          Navigator.of(context).pop();
                          context.go('/browse?keyword=$value');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
