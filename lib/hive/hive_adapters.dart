import 'package:hive_ce/hive.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/core/models/settings/content_settings_model.dart';
import 'package:shonenx/core/models/settings/download_settings_model.dart';
import 'package:shonenx/core/models/settings/experimental_model.dart';
import 'package:shonenx/core/models/settings/player_model.dart';
import 'package:shonenx/core/models/settings/subtitle_appearance_model.dart';
import 'package:shonenx/core/models/settings/theme_model.dart';
import 'package:shonenx/core/models/settings/ui_model.dart';

@GenerateAdapters([
  AdapterSpec<ThemeModel>(),
  AdapterSpec<UiSettings>(),
  AdapterSpec<PlayerModel>(),
  AdapterSpec<HomePageModel>(),
  AdapterSpec<AnimeWatchProgressEntry>(),
  AdapterSpec<EpisodeProgress>(),
  AdapterSpec<SubtitleAppearanceModel>(),
  AdapterSpec<ExperimentalFeaturesModel>(),
  AdapterSpec<DownloadItem>(),
  AdapterSpec<DownloadStatus>(),
  AdapterSpec<DownloadSettingsModel>(),
  AdapterSpec<ContentSettingsModel>(),
  AdapterSpec<UniversalNews>(),
  AdapterSpec<AnimeCardMode>(),
  AdapterSpec<SpotlightCardMode>(),
])
part 'hive_adapters.g.dart';
