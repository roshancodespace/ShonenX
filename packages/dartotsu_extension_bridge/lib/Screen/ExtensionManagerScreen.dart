import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef ExtensionScreenBuilder =
    Widget Function(
      ItemType itemType,
      bool isInstalled,
      String searchQuery,
      String selectedLanguage,
    );

abstract class ExtensionManagerScreen<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  late final TabController tabController;

  final manager = Get.find<ExtensionManager>().currentManager;

  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<String> selectedLanguage = ValueNotifier('All');

  Future<void> Function(List<String> repoUrl, ItemType type) get onRepoSaved;

  @override
  void initState() {
    super.initState();

    int totalTabs = 0;
    if (manager.supportsAnime) totalTabs += 2;
    if (manager.supportsManga) totalTabs += 2;
    if (manager.supportsNovel) totalTabs += 2;

    tabController = TabController(length: totalTabs, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    selectedLanguage.dispose();
    super.dispose();
  }

  Text title(TextTheme textTheme);

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

  List<Widget> _buildTabs(BuildContext context) {
    final tabs = <Widget>[];

    void addTabs(String label, int installed, int available) {
      tabs.add(tabWidget(context, 'Installed $label', installed));
      tabs.add(tabWidget(context, 'Available $label', available));
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

  List<Widget> _buildTabViews(ColorScheme theme) {
    final query = searchController.text;
    final lang = selectedLanguage.value;

    final views = <Widget>[];

    void add(ItemType type, List installed, List available) {
      views.add(
        installed.isEmpty
            ? Center(child: Text('No installed ${type.name} extensions'))
            : extensionScreenBuilder(type, true, query, lang),
      );

      views.add(
        available.isEmpty
            ? Center(child: Text('No available ${type.name} extensions'))
            : extensionScreenBuilder(type, false, query, lang),
      );
    }

    if (manager.supportsAnime) {
      add(
        ItemType.anime,
        manager.installedAnimeExtensions.value,
        manager.availableAnimeExtensions.value,
      );
    }

    if (manager.supportsManga) {
      add(
        ItemType.manga,
        manager.installedMangaExtensions.value,
        manager.availableMangaExtensions.value,
      );
    }

    if (manager.supportsNovel) {
      add(
        ItemType.novel,
        manager.installedNovelExtensions.value,
        manager.availableNovelExtensions.value,
      );
    }

    return views;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: const BouncingScrollPhysics(),
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scaffold(
        appBar: AppBar(
          title: title(Theme.of(context).textTheme),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: extensionActions(
            context,
            tabController,
            selectedLanguage.value,
            onRepoSaved,
            (lang) => selectedLanguage.value = lang,
          ),
        ),
        body: Column(
          children: [
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabs: _buildTabs(context),
            ),
            const SizedBox(height: 8),
            searchBar(context, searchController, () => setState(() {})),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: _buildTabViews(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
