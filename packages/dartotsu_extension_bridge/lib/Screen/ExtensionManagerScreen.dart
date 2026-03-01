import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ExtensionManager.dart';
import '../Models/Source.dart';

///Extend this class to create a screen for managing extensions.
///If you don't like manual labor
abstract class ExtensionManagerScreen<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  late TabController _tabBarController;
  var manager = Get.find<ExtensionManager>().currentManager;
  final _selectedLanguage = 'All'.obs;
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    int totalTabs = 0;
    if (manager.supportsAnime) totalTabs += 2;
    if (manager.supportsManga) totalTabs += 2;
    if (manager.supportsNovel) totalTabs += 2;
    _tabBarController = TabController(length: totalTabs, vsync: this);
    _tabBarController.animateTo(0);
  }

  @override
  void dispose() {
    super.dispose();
    _tabBarController.dispose();
    _textEditingController.dispose();
    _selectedLanguage.close();
  }

  Text get title;

  ExtensionScreenBuilder get extensionScreenBuilder;

  List<Widget> extensionActions(
    BuildContext context,
    TabController tabController,
    String currentLanguage,
    Future<void> Function(List<String> repoUrl, ItemType type) onRepoSaved,
    void Function(String currentLanguage) onLanguageChanged,
  );

  Widget tabWidget(BuildContext context, String label, int count);

  Widget searchBar(
    BuildContext context,
    TextEditingController textEditingController,
    void Function() onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: const BouncingScrollPhysics(),
        scrollbars: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: title,
            iconTheme: IconThemeData(color: theme.primary),
            actions: [
              ...extensionActions(
                context,
                _tabBarController,
                _selectedLanguage.value,
                manager.onRepoSaved,
                (lang) => setState(() => _selectedLanguage.value = lang),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Obx(
                () => TabBar(
                  controller: _tabBarController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.label,
                  dragStartBehavior: DragStartBehavior.start,
                  tabs: _buildTabs(context),
                ),
              ),
              const SizedBox(height: 8),
              searchBar(
                context,
                _textEditingController,
                () => setState(
                  () {},
                ), // Trigger rebuild on search change _textEditingController handles the text input
              ),
              const SizedBox(height: 8),
              Obx(
                () => Expanded(
                  child: TabBarView(
                    controller: _tabBarController,
                    children: _buildTabViews(theme, extensionScreenBuilder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    final manager = Get.find<ExtensionManager>().currentManager;

    List<Widget> tabs = [];

    void addTabs(String label, int installedCount, int availableCount) {
      tabs.add(tabWidget(context, 'Installed $label', installedCount));
      tabs.add(tabWidget(context, 'Available $label', availableCount));
    }

    if (manager.supportsAnime) {
      addTabs(
        'anime',
        manager.installedAnimeExtensions.value.length,
        manager.availableAnimeExtensions.value.length,
      );
    }
    if (manager.supportsManga) {
      addTabs(
        'manga',
        manager.installedMangaExtensions.value.length,
        manager.availableMangaExtensions.value.length,
      );
    }
    if (manager.supportsNovel) {
      addTabs(
        'novel',
        manager.installedNovelExtensions.value.length,
        manager.availableNovelExtensions.value.length,
      );
    }

    return tabs;
  }

  List<Widget> _buildTabViews(
    ColorScheme theme,
    ExtensionScreenBuilder builder,
  ) {
    final manager = Get.find<ExtensionManager>().currentManager;
    final query = _textEditingController.text;
    final lang = _selectedLanguage.value;

    List<Widget> views = [];

    void addViews(ItemType type, List installed, List available) {
      views.add(
        installed.isEmpty
            ? _emptyMessage('No installed ${type.name} extensions', theme)
            : builder(type, true, query, lang),
      );
      views.add(
        available.isEmpty
            ? _emptyMessage('No available ${type.name} extensions', theme)
            : builder(type, false, query, lang),
      );
    }

    if (manager.supportsAnime) {
      addViews(
        ItemType.anime,
        manager.installedAnimeExtensions.value,
        manager.availableAnimeExtensions.value,
      );
    }
    if (manager.supportsManga) {
      addViews(
        ItemType.manga,
        manager.installedMangaExtensions.value,
        manager.availableMangaExtensions.value,
      );
    }
    if (manager.supportsNovel) {
      addViews(
        ItemType.novel,
        manager.installedNovelExtensions.value,
        manager.availableNovelExtensions.value,
      );
    }

    return views;
  }

  Widget _emptyMessage(String message, ColorScheme theme) {
    return Center(
      child: Text(message, style: TextStyle(color: theme.onSurface)),
    );
  }
}

typedef ExtensionScreenBuilder =
    Widget Function(
      ItemType itemType,
      bool isInstalled,
      String searchQuery,
      String selectedLanguage,
    );
