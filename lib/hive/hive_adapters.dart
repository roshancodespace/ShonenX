import 'package:hive_ce/hive.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/core_mangayomi/models/track_search.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';

@GenerateAdapters([
  AdapterSpec<TrackSearch>(),
  AdapterSpec<ThemeModel>(),
  AdapterSpec<UiModel>(),
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
])
part 'hive_adapters.g.dart';
