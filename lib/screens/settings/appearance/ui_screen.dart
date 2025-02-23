import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/widgets/anime/anime_card_v2.dart';

class UISettingsScreen extends StatefulWidget {
  const UISettingsScreen({super.key});

  @override
  State<UISettingsScreen> createState() => _UISettingsScreenState();
}

class _UISettingsScreenState extends State<UISettingsScreen> {
  UISettingsModel _uiSettings = UISettingsModel();
  bool _isBoxInitialized = false;
  late SettingsBox? _settingsBox;

  final anime_media.Media animeMedia = anime_media.Media(
    id: 1,
    coverImage: anime_media.CoverImage(
      large:
          'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
      medium:
          'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
    ),
    title: anime_media.Title(
      english: "One Piece",
      romaji: "One Piece",
      native: "One Piece",
    ),
    format: 'TV',
    status: 'Completed',
    genres: ['Action', 'Adventure', 'Comedy'],
    episodes: 220,
    season: 'Fall',
  );

  @override
  void initState() {
    super.initState();
    _initializeSettingsBox();
  }

  @override 
  void dispose() {
    _saveSettings();
    super.dispose();
  }

  Future<void> _initializeSettingsBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    _isBoxInitialized = true;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_isBoxInitialized) {
      final settings = _settingsBox?.getSettings();
      if (settings != null) {
        setState(() {
          _uiSettings = settings.uiSettings ?? UISettingsModel();
        });
      }
    }
  }

  void _saveSettings() {
    if (!_isBoxInitialized) return;
    _settingsBox?.updateUISettings(_uiSettings);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            _saveSettings();
            context.pop();
          },
          icon: Icon(Iconsax.arrow_left_2, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
          ),
        ),
        title: const Text(
          'UI Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Text(
                'Customize Interface',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingsGroup(
                context,
                title: 'Layout',
                items: [
                  // SwitchSettingsItem(
                  //   icon: Iconsax.grid_2,
                  //   title: 'Compact Mode',
                  //   description: 'Use a denser layout for lists and grids',
                  //   value: _uiSettings.compactMode,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _uiSettings = _uiSettings.copyWith(compactMode: value);
                  //     });
                  //   },
                  // ),
                  _SettingsItem(
                    icon: Iconsax.home,
                    title: 'Default Tab',
                    description:
                        'Set the tab shown on app launch (${_uiSettings.defaultTab})',
                    onTap: () => _showDefaultTabDialog(context),
                    disabled: true,
                  ),
                  _SettingsItem(
                    icon: Iconsax.grid_3,
                    title: 'Layout Style',
                    description:
                        'Choose between grid or list view (${_uiSettings.layoutStyle})',
                    onTap: () => _showLayoutStyleDialog(context),
                    disabled: true,
                  ),
                ],
              ),
              _buildSettingsGroup(
                context,
                title: 'Content Display',
                items: [
                  // SwitchSettingsItem(
                  //   icon: Iconsax.image,
                  //   title: 'Show Thumbnails',
                  //   description: 'Display anime thumbnails in lists',
                  //   value: _uiSettings.showThumbnails,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _uiSettings =
                  //           _uiSettings.copyWith(showThumbnails: value);
                  //     });
                  //   },
                  // ),
                  _SettingsItem(
                    icon: Iconsax.card,
                    title: 'Card Style',
                    description:
                        'Customize card appearance (${_uiSettings.cardStyle})',
                    onTap: () => _showCardStyleDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 3,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            surfaceTintColor: Colors.transparent,
            color: colorScheme.surface,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    item,
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDefaultTabDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Default Tab',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Home', 'Search', 'Library', 'Watchlist'].map((tab) {
                  return ListTile(
                    
                    title: Text(
                      tab,
                      style: GoogleFonts.montserrat(
                        color: colorScheme.onSurface,
                        fontWeight: _uiSettings.defaultTab == tab
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _uiSettings.defaultTab == tab
                        ? Icon(Iconsax.tick_circle, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _uiSettings = _uiSettings.copyWith(defaultTab: tab);
                      });
                      setDialogState(() {});
                    },
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  void _showCardStyleDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        String selectedStyle =
            _uiSettings.cardStyle; // Track the selected style

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Card Style',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown for card styles
                  DropdownButtonFormField<String>(
                    value: selectedStyle,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    dropdownColor: colorScheme.surfaceVariant,
                    icon:
                        Icon(Iconsax.arrow_down_1, color: colorScheme.onSurface),
                    style: TextStyle(color: colorScheme.onSurface),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedStyle = newValue!; // Update the selected style
                      });
                    },
                    items: [
                      'Classic',
                      'Compact',
                      'Minimal',
                      'Poster',
                      'Outlined'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.montserrat(),),
                        
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Preview of the selected card style
                  _buildCardPreview(context, selectedStyle),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _uiSettings = _uiSettings.copyWith(
                      cardStyle: selectedStyle); // Save the selected style
                });
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Save',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardPreview(BuildContext context, String style) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedAnimeCard(
            anime: animeMedia,
            tag: 'preview_$style',
            mode: style, // Use the selected style for the preview
          ),
        ],
      ),
    );
  }

  void _showLayoutStyleDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Layout Style',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Grid', 'List'].map((style) {
                  return ListTile(
                    title: Text(
                      style,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: _uiSettings.layoutStyle == style
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _uiSettings.layoutStyle == style
                        ? Icon(Iconsax.tick_circle, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _uiSettings = _uiSettings.copyWith(layoutStyle: style);
                      });
                      setDialogState(() {});
                    },
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = false);
        }
      },
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(widget.disabled ? 0.05 : 0.2),
                      colorScheme.primary.withOpacity(widget.disabled ? 0.03 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.disabled
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.disabled
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.3 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: colorScheme.onSurface.withOpacity(widget.disabled ? 0.2 : 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
