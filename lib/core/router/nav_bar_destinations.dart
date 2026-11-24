import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';

class NavBarDestination {
  final IconData icon;
  final String label;

  const NavBarDestination(this.icon, this.label);
}

List<NavBarDestination> navBarDestinations(BuildContext context) {
  final l10n = context.l10n;
  return [
    NavBarDestination(Icons.home_outlined, l10n.navHome),
    NavBarDestination(Icons.search_rounded, l10n.navSearch),
    NavBarDestination(Icons.library_books_outlined, l10n.navLibrary),
  ];
}
