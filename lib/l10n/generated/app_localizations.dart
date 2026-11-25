import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_yue.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('yue'),
  ];

  /// Navigation bar label for Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation bar label for Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Navigation bar label for Library
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Navigation bar label for Downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// Navigation bar label for Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Navigation bar label for Discover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// Generic cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Generic delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Generic error text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// Generic loading state text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Generic none text
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// Generic unknown text
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// Generic search action text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// Generic filter action text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// Generic clear action text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Generic back action text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Generic apply action text
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// Generic reset action text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Generic edit action text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Generic share action text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Generic copy action text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Snackbar message when content is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// Generic refresh action text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// Generic success message title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// Generic warning message title
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get commonWarning;

  /// Generic failure message
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get commonFailed;

  /// Generic remove action text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Home section title for watching history
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get homeContinueWatching;

  /// Home section title for reading history
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get homeContinueReading;

  /// Home section title for trending anime
  ///
  /// In en, this message translates to:
  /// **'Trending Anime'**
  String get homeTrendingAnime;

  /// Home section title for trending manga
  ///
  /// In en, this message translates to:
  /// **'Trending Manga'**
  String get homeTrendingManga;

  /// Home section title for top rated anime
  ///
  /// In en, this message translates to:
  /// **'Top Rated Anime'**
  String get homeTopRatedAnime;

  /// Home section title for top rated manga
  ///
  /// In en, this message translates to:
  /// **'Top Rated Manga'**
  String get homeTopRatedManga;

  /// Home section title for popular anime
  ///
  /// In en, this message translates to:
  /// **'Popular Anime'**
  String get homePopularAnime;

  /// Home section title for popular manga
  ///
  /// In en, this message translates to:
  /// **'Popular Manga'**
  String get homePopularManga;

  /// Home section title for today's airing schedule
  ///
  /// In en, this message translates to:
  /// **'Airing Today'**
  String get homeAiringToday;

  /// Home section title for recently updated media
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get homeRecentlyUpdated;

  /// Home section title for recent episodes
  ///
  /// In en, this message translates to:
  /// **'Recent Episodes'**
  String get homeRecentEpisodes;

  /// Home section title for recent chapters
  ///
  /// In en, this message translates to:
  /// **'Recent Chapters'**
  String get homeRecentChapters;

  /// Action button to view all items in a section
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search anime, manga, characters...'**
  String get discoverySearchHint;

  /// Empty search results state
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get discoveryNoResults;

  /// Genre filter header
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get discoveryGenres;

  /// Season filter header
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get discoverySeasons;

  /// Year filter header
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get discoveryYear;

  /// Media format filter header
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get discoveryFormat;

  /// Media status filter header
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get discoveryStatus;

  /// Episodes section header in media details
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get detailsEpisodes;

  /// Chapters section header in media details
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get detailsChapters;

  /// Synopsis section header in media details
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get detailsSynopsis;

  /// Genres label in media details
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get detailsGenres;

  /// Status label in media details
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailsStatus;

  /// Airing date label
  ///
  /// In en, this message translates to:
  /// **'Airing Date'**
  String get detailsAiringDate;

  /// Score label
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get detailsScore;

  /// Rank label
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get detailsRank;

  /// Studios label
  ///
  /// In en, this message translates to:
  /// **'Studios'**
  String get detailsStudios;

  /// Author label
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get detailsAuthor;

  /// Primary action button to watch anime
  ///
  /// In en, this message translates to:
  /// **'Watch Now'**
  String get detailsWatchNow;

  /// Primary action button to read manga
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get detailsReadNow;

  /// Action button to add media to user library
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get detailsAddToLibrary;

  /// Indicator that media is already in library
  ///
  /// In en, this message translates to:
  /// **'In Library'**
  String get detailsInLibrary;

  /// Action button to share media link
  ///
  /// In en, this message translates to:
  /// **'Share Media'**
  String get detailsShareMedia;

  /// Characters section header in media details
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get detailsCharacters;

  /// Staff section header in media details
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get detailsStaff;

  /// Trailers section header in media details
  ///
  /// In en, this message translates to:
  /// **'Trailers'**
  String get detailsTrailers;

  /// Related media section header
  ///
  /// In en, this message translates to:
  /// **'Relations'**
  String get detailsRelations;

  /// Recommended media section header
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get detailsRecommendations;

  /// Empty state for episodes
  ///
  /// In en, this message translates to:
  /// **'No episodes found for this source'**
  String get detailsNoEpisodesFound;

  /// Empty state for chapters
  ///
  /// In en, this message translates to:
  /// **'No chapters found for this source'**
  String get detailsNoChaptersFound;

  /// Player quality settings option
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get playerQuality;

  /// Player server selection option
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get playerServer;

  /// Playback speed selection option
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerSpeed;

  /// Player audio track selection option
  ///
  /// In en, this message translates to:
  /// **'Audio Track'**
  String get playerAudioTrack;

  /// Player subtitle track selection option
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get playerSubtitleTrack;

  /// Auto play toggle label
  ///
  /// In en, this message translates to:
  /// **'Auto Play'**
  String get playerAutoPlay;

  /// Auto skip intro toggle label
  ///
  /// In en, this message translates to:
  /// **'Auto Skip Intro'**
  String get playerAutoSkipIntro;

  /// Auto skip outro toggle label
  ///
  /// In en, this message translates to:
  /// **'Auto Skip Outro'**
  String get playerAutoSkipOutro;

  /// Next episode button tooltip
  ///
  /// In en, this message translates to:
  /// **'Next Episode'**
  String get playerNextEpisode;

  /// Previous episode button tooltip
  ///
  /// In en, this message translates to:
  /// **'Previous Episode'**
  String get playerPreviousEpisode;

  /// Lock video controls button tooltip
  ///
  /// In en, this message translates to:
  /// **'Lock Controls'**
  String get playerLockControls;

  /// Unlock video controls button tooltip
  ///
  /// In en, this message translates to:
  /// **'Unlock Controls'**
  String get playerUnlockControls;

  /// Aspect ratio settings option
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get playerAspectRatio;

  /// Fit video to screen option
  ///
  /// In en, this message translates to:
  /// **'Fit to Screen'**
  String get playerFitToScreen;

  /// Error message when video playback fails
  ///
  /// In en, this message translates to:
  /// **'Playback Error'**
  String get playerPlaybackError;

  /// Message when current video source fails
  ///
  /// In en, this message translates to:
  /// **'Source unavailable, please try another server'**
  String get playerSourceUnavailable;

  /// Buffering status indicator
  ///
  /// In en, this message translates to:
  /// **'Buffering...'**
  String get playerBuffering;

  /// Subtitle translation settings title
  ///
  /// In en, this message translates to:
  /// **'Subtitle Translation'**
  String get playerSubtitleTranslation;

  /// Subtitle translation target language label
  ///
  /// In en, this message translates to:
  /// **'Target Language'**
  String get playerSubtitleTargetLanguage;

  /// Reader mode settings option
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readerMode;

  /// Continuous vertical webtoon reading mode
  ///
  /// In en, this message translates to:
  /// **'Webtoon'**
  String get readerModeWebtoon;

  /// Paged reading mode
  ///
  /// In en, this message translates to:
  /// **'Paged'**
  String get readerModePaged;

  /// Continuous horizontal reading mode
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get readerModeContinuous;

  /// Reading direction settings option
  ///
  /// In en, this message translates to:
  /// **'Reading Direction'**
  String get readerReadingDirection;

  /// Left to right reading direction
  ///
  /// In en, this message translates to:
  /// **'Left to Right'**
  String get readerLeftToRight;

  /// Right to left reading direction (Manga)
  ///
  /// In en, this message translates to:
  /// **'Right to Left'**
  String get readerRightToLeft;

  /// Vertical reading direction
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get readerVertical;

  /// Reader background color settings option
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get readerBackgroundColor;

  /// Fit manga page to screen width
  ///
  /// In en, this message translates to:
  /// **'Fit Width'**
  String get readerFitWidth;

  /// Fit manga page to screen height
  ///
  /// In en, this message translates to:
  /// **'Fit Height'**
  String get readerFitHeight;

  /// Zoom label
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get readerZoom;

  /// Page indicator in manga reader
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String readerPageNumber(int current, int total);

  /// Library tab label for anime
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get libraryAnimeTab;

  /// Library tab label for manga
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get libraryMangaTab;

  /// Empty library headline
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmpty;

  /// Empty library subtext
  ///
  /// In en, this message translates to:
  /// **'Track your favorite anime and manga here'**
  String get libraryEmptyDescription;

  /// Tracking settings and status title
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingTitle;

  /// Tracker connected status
  ///
  /// In en, this message translates to:
  /// **'Connected as {username}'**
  String trackingConnectedAs(String username);

  /// Tracker not connected status
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get trackingNotConnected;

  /// Button to connect AniList account
  ///
  /// In en, this message translates to:
  /// **'Connect AniList'**
  String get trackingConnectAnilist;

  /// Button to connect MyAnimeList account
  ///
  /// In en, this message translates to:
  /// **'Connect MyAnimeList'**
  String get trackingConnectMal;

  /// Anime tracking status: Watching
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get trackingStatusWatching;

  /// Manga tracking status: Reading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get trackingStatusReading;

  /// Tracking status: Completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackingStatusCompleted;

  /// Anime tracking status: Plan to Watch
  ///
  /// In en, this message translates to:
  /// **'Plan to Watch'**
  String get trackingStatusPlanToWatch;

  /// Manga tracking status: Plan to Read
  ///
  /// In en, this message translates to:
  /// **'Plan to Read'**
  String get trackingStatusPlanToRead;

  /// Tracking status: On Hold
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get trackingStatusOnHold;

  /// Tracking status: Dropped
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get trackingStatusDropped;

  /// Action to update tracking progress
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get trackingUpdateProgress;

  /// Tracking score label
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get trackingScore;

  /// Downloads screen and section title
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// Active downloads tab
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get downloadsActive;

  /// Completed downloads tab
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadsCompleted;

  /// Action button to pause all downloads
  ///
  /// In en, this message translates to:
  /// **'Pause All'**
  String get downloadsPauseAll;

  /// Action button to resume all downloads
  ///
  /// In en, this message translates to:
  /// **'Resume All'**
  String get downloadsResumeAll;

  /// Action button to cancel all downloads
  ///
  /// In en, this message translates to:
  /// **'Cancel All'**
  String get downloadsCancelAll;

  /// Empty state for downloads
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsNoDownloads;

  /// Confirmation message before deleting a downloaded episode
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this download?'**
  String get downloadsDeleteConfirm;

  /// Main settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// General settings section title
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// Appearance settings title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Appearance settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Theme, pure black, accent colors'**
  String get settingsAppearanceSubtitle;

  /// Player settings title
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get settingsPlayer;

  /// Player settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Gestures, default quality, skips'**
  String get settingsPlayerSubtitle;

  /// Reader settings title
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get settingsReader;

  /// Reader settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Reading mode, background, scale'**
  String get settingsReaderSubtitle;

  /// Extensions settings title
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get settingsExtensions;

  /// Extensions settings subtitle
  ///
  /// In en, this message translates to:
  /// **'External runtime engines & native sources'**
  String get settingsExtensionsSubtitle;

  /// Addons settings title
  ///
  /// In en, this message translates to:
  /// **'Addons'**
  String get settingsAddons;

  /// Addons settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Torrent engines & streaming helpers'**
  String get settingsAddonsSubtitle;

  /// Downloads settings title
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// Downloads settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Download location, file naming'**
  String get settingsDownloadsSubtitle;

  /// Content settings title
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get settingsContent;

  /// Content settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Content filters, 18+ toggle'**
  String get settingsContentSubtitle;

  /// Security settings title
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get settingsSecurity;

  /// Security settings subtitle
  ///
  /// In en, this message translates to:
  /// **'PIN lock, biometrics, app protection'**
  String get settingsSecuritySubtitle;

  /// Tracking settings title
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get settingsTracking;

  /// Tracking settings subtitle
  ///
  /// In en, this message translates to:
  /// **'AniList, MyAnimeList connections'**
  String get settingsTrackingSubtitle;

  /// Backup settings title
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackup;

  /// Backup settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Export or import your data'**
  String get settingsBackupSubtitle;

  /// UI settings title
  ///
  /// In en, this message translates to:
  /// **'UI'**
  String get settingsUi;

  /// UI settings subtitle
  ///
  /// In en, this message translates to:
  /// **'UI settings, cards, layouts'**
  String get settingsUiSubtitle;

  /// Home settings title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get settingsHome;

  /// Home settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Home screen settings and sections'**
  String get settingsHomeSubtitle;

  /// Notifications settings title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Notifications settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage active subscriptions and reminders'**
  String get settingsNotificationsSubtitle;

  /// Cache settings title
  ///
  /// In en, this message translates to:
  /// **'Cache Manager'**
  String get settingsCache;

  /// Cache settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Clear cache and thumbnails'**
  String get settingsCacheSubtitle;

  /// Updates settings title
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// Updates settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Check for updates and release preferences'**
  String get settingsUpdatesSubtitle;

  /// About settings title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// About settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Version, developer, and links'**
  String get settingsAboutSubtitle;

  /// Discord settings title
  ///
  /// In en, this message translates to:
  /// **'Discord RPC'**
  String get settingsDiscordRpc;

  /// Discord settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Send Rich Presence to Discord'**
  String get settingsDiscordRpcSubtitle;

  /// Troubleshoot settings title
  ///
  /// In en, this message translates to:
  /// **'Troubleshoot & Repair'**
  String get settingsTroubleshoot;

  /// Troubleshoot settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Force fix missing episodes and broken matches'**
  String get settingsTroubleshootSubtitle;

  /// Debug settings title
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsDebug;

  /// Debug settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Test notifications and UI components'**
  String get settingsDebugSubtitle;

  /// Logs settings title
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsLogs;

  /// Logs settings subtitle
  ///
  /// In en, this message translates to:
  /// **'View, copy, and export app logs'**
  String get settingsLogsSubtitle;

  /// Permissions settings title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsPermissions;

  /// Permissions settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage app permissions'**
  String get settingsPermissionsSubtitle;

  /// Support settings section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// Data and sync settings section title
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get settingsDataSync;

  /// Misc settings section title
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get settingsMisc;

  /// Integrations settings section title
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsIntegrations;

  /// Advanced settings section title
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// Language selection tile title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language selection tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Select application interface language'**
  String get settingsLanguageSubtitle;

  /// Option to follow system default locale
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsSystemDefault;

  /// Theme mode settings label
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Pure black dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'AMOLED (Pure Black)'**
  String get settingsAmoled;

  /// Dynamic material color toggle
  ///
  /// In en, this message translates to:
  /// **'Dynamic Colors'**
  String get settingsDynamicColor;

  /// Accent color selector title
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get settingsAccentColor;

  /// UI scale slider title
  ///
  /// In en, this message translates to:
  /// **'UI Scale'**
  String get settingsUiScaling;

  /// UI corner roundness slider title
  ///
  /// In en, this message translates to:
  /// **'Corner Roundness'**
  String get settingsRoundness;

  /// Adult content toggle label
  ///
  /// In en, this message translates to:
  /// **'18+ Adult Content'**
  String get settingsAdultContent;

  /// Preferred title language label
  ///
  /// In en, this message translates to:
  /// **'Preferred Title Language'**
  String get settingsTitleLanguage;

  /// Clear cache button text
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// Snackbar message when cache is cleared
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// Check for updates action button
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckUpdates;

  /// Version display string
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// TV interface app bar title
  ///
  /// In en, this message translates to:
  /// **'ShonenX TV'**
  String get tvTitle;

  /// TV navigation Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tvHome;

  /// TV navigation Discover tab
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tvDiscover;

  /// TV navigation Library tab
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tvLibrary;

  /// TV navigation Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tvSettings;

  /// Pluralized episode count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No episodes} =1{1 episode} other{{count} episodes}}'**
  String episodesCount(int count);

  /// Pluralized chapter count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No chapters} =1{1 chapter} other{{count} chapters}}'**
  String chaptersCount(int count);

  /// Pluralized download count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No downloads} =1{1 download} other{{count} downloads}}'**
  String downloadsCount(int count);

  /// Pluralized search result count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// Pluralized notification count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notifications} =1{1 notification} other{{count} notifications}}'**
  String notificationsCount(int count);

  /// Pluralized selected item count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item selected} other{{count} items selected}}'**
  String itemsSelected(int count);

  /// Localization for homeGoodMorning
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// Localization for homeGoodAfternoon
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// Localization for homeGoodEvening
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// Localization for homeNoActiveSections
  ///
  /// In en, this message translates to:
  /// **'No active sections or sources'**
  String get homeNoActiveSections;

  /// Localization for libraryFromLibrary
  ///
  /// In en, this message translates to:
  /// **'From Library'**
  String get libraryFromLibrary;

  /// Localization for libraryCloud
  ///
  /// In en, this message translates to:
  /// **'Cloud Library'**
  String get libraryCloud;

  /// Localization for libraryLocal
  ///
  /// In en, this message translates to:
  /// **'Local Library'**
  String get libraryLocal;

  /// Localization for libraryEmptyList
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get libraryEmptyList;

  /// Localization for historySearchHint
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get historySearchHint;

  /// Localization for historyEmpty
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get historyEmpty;

  /// Localization for historySelectItems
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get historySelectItems;

  /// Localization for historySelectAll
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get historySelectAll;

  /// Localization for historyDeselectAll
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get historyDeselectAll;

  /// Localization for historyPickUpWhereYouLeftOff
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get historyPickUpWhereYouLeftOff;

  /// Localization for historySelectItemsToDelete
  ///
  /// In en, this message translates to:
  /// **'Select items to delete'**
  String get historySelectItemsToDelete;

  /// Localization for historyDeleteSelected
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get historyDeleteSelected;

  /// Localization for historyCancelSelection
  ///
  /// In en, this message translates to:
  /// **'Cancel Selection'**
  String get historyCancelSelection;

  /// Localization for historyDeletedCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 item from history} other{Deleted {count} items from history}}'**
  String historyDeletedCount(int count);

  /// Localization for historyRemoved
  ///
  /// In en, this message translates to:
  /// **'Removed from history'**
  String get historyRemoved;

  /// Localization for historyOpenDetails
  ///
  /// In en, this message translates to:
  /// **'Open Details (No Play)'**
  String get historyOpenDetails;

  /// Localization for downloadsQueue
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get downloadsQueue;

  /// Localization for downloadsOfflineFiles
  ///
  /// In en, this message translates to:
  /// **'Offline Files'**
  String get downloadsOfflineFiles;

  /// Localization for downloadsQueueEmpty
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get downloadsQueueEmpty;

  /// Localization for downloadsQueueEmptySubtitle
  ///
  /// In en, this message translates to:
  /// **'Active downloads will appear here'**
  String get downloadsQueueEmptySubtitle;

  /// Localization for detailsAbout
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get detailsAbout;

  /// Localization for detailsDiscussion
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get detailsDiscussion;

  /// Localization for detailsInformation
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get detailsInformation;

  /// Localization for detailsStudio
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get detailsStudio;

  /// Localization for detailsDuration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailsDuration;

  /// Localization for detailsMinutes
  ///
  /// In en, this message translates to:
  /// **'{count} mins'**
  String detailsMinutes(int count);

  /// Localization for detailsVolumes
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get detailsVolumes;

  /// Localization for detailsFavorites
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get detailsFavorites;

  /// Localization for detailsPopularity
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get detailsPopularity;

  /// Localization for detailsAlternativeTitles
  ///
  /// In en, this message translates to:
  /// **'Alternative Titles'**
  String get detailsAlternativeTitles;

  /// Localization for detailsTags
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get detailsTags;

  /// Localization for detailsExternalLinks
  ///
  /// In en, this message translates to:
  /// **'External Links'**
  String get detailsExternalLinks;

  /// Localization for detailsAddTracker
  ///
  /// In en, this message translates to:
  /// **'Add Tracker'**
  String get detailsAddTracker;

  /// Localization for detailsManageTrackers
  ///
  /// In en, this message translates to:
  /// **'Manage Trackers'**
  String get detailsManageTrackers;

  /// Localization for detailsSyncError
  ///
  /// In en, this message translates to:
  /// **'Sync Error'**
  String get detailsSyncError;

  /// Localization for detailsManualMatch
  ///
  /// In en, this message translates to:
  /// **'Manual Match'**
  String get detailsManualMatch;

  /// Localization for detailsRetrySearch
  ///
  /// In en, this message translates to:
  /// **'Retry Search'**
  String get detailsRetrySearch;

  /// Localization for readerPreviousChapter
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter'**
  String get readerPreviousChapter;

  /// Localization for readerNextChapter
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get readerNextChapter;

  /// Localization for readerPreviousPage
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get readerPreviousPage;

  /// Localization for readerNextPage
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get readerNextPage;

  /// Localization for readerChaptersList
  ///
  /// In en, this message translates to:
  /// **'Chapters List'**
  String get readerChaptersList;

  /// Localization for readerSettings
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// Localization for settingsThemes
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get settingsThemes;

  /// Localization for settingsEffects
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get settingsEffects;

  /// Localization for settingsWallpaper
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get settingsWallpaper;

  /// Localization for settingsResetDefaults
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetDefaults;

  /// Localization for settingsThemeResetSuccess
  ///
  /// In en, this message translates to:
  /// **'Theme settings reset to default'**
  String get settingsThemeResetSuccess;

  /// Localization for settingsMode
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get settingsMode;

  /// Localization for settingsDisplay
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsDisplay;

  /// Localization for settingsStorage
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// Localization for settingsLocation
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get settingsLocation;

  /// Localization for settingsFilters
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get settingsFilters;

  /// Localization for settingsSafe
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get settingsSafe;

  /// Localization for settingsMixed
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get settingsMixed;

  /// Localization for settingsAdultOnly
  ///
  /// In en, this message translates to:
  /// **'18+ Only'**
  String get settingsAdultOnly;

  /// Localization for settingsLinks
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get settingsLinks;

  /// Localization for settingsReportIssue
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get settingsReportIssue;

  /// Localization for settingsDeveloper
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// Localization for settingsContributors
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get settingsContributors;

  /// Localization for settingsMaxCacheSize
  ///
  /// In en, this message translates to:
  /// **'Maximum Cache Size'**
  String get settingsMaxCacheSize;

  /// Localization for settingsClearEntireCache
  ///
  /// In en, this message translates to:
  /// **'Clear Entire Cache'**
  String get settingsClearEntireCache;

  /// Label for detailsEnglish
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get detailsEnglish;

  /// Label for detailsRomaji
  ///
  /// In en, this message translates to:
  /// **'Romaji'**
  String get detailsRomaji;

  /// Label for detailsNative
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get detailsNative;

  /// Label for detailsSynonyms
  ///
  /// In en, this message translates to:
  /// **'Synonyms'**
  String get detailsSynonyms;

  /// Title for the support development tile on the settings index
  ///
  /// In en, this message translates to:
  /// **'Support Development'**
  String get settingsSupportDevelopment;

  /// Subtitle for the support development tile on the settings index
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee to keep the project alive and ad-free!'**
  String get settingsSupportDevelopmentSubtitle;

  /// Tooltip for the info button on settings dropdown tiles
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get settingsInfo;

  /// Label for the button that opens customization options for a selected setting
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get settingsCustomize;

  /// Label for the Media Kit engine settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAdvancedSettings;

  /// Section title for experimental UI options
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get uiSettingsExperimental;

  /// Section title for layout and sheet motion settings
  ///
  /// In en, this message translates to:
  /// **'Layout & Motion'**
  String get uiSettingsLayoutMotion;

  /// Subtitle directing theme colors to the Appearance section
  ///
  /// In en, this message translates to:
  /// **'Global sizing and sheet motion — theme colors live under Appearance'**
  String get uiSettingsLayoutMotionSubtitle;

  /// Section title for home screen settings
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get uiSettingsHomeScreen;

  /// Section title for media card settings
  ///
  /// In en, this message translates to:
  /// **'Media Cards'**
  String get uiSettingsMediaCards;

  /// Section title for episode settings
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get uiSettingsEpisodes;

  /// Section title for navigation bar settings
  ///
  /// In en, this message translates to:
  /// **'Navigation Bar'**
  String get uiSettingsNavigationBar;

  /// Title for the experimental TV / new UI toggle
  ///
  /// In en, this message translates to:
  /// **'Experimental TV / New UI'**
  String get uiSettingsExperimentalTvTitle;

  /// Subtitle for the experimental TV / new UI toggle
  ///
  /// In en, this message translates to:
  /// **'A cinematic, spatial interface built for D-pad, remote, and keyboard navigation'**
  String get uiSettingsExperimentalTvSubtitle;

  /// Title for the sizing and corners appearance sheet entry
  ///
  /// In en, this message translates to:
  /// **'Sizing & Corners'**
  String get uiSettingsSizingTitle;

  /// Subtitle for the sizing and corners appearance sheet entry
  ///
  /// In en, this message translates to:
  /// **'Adjust corner radius, widget scale, and text scale'**
  String get uiSettingsSizingSubtitle;

  /// Title for the sheet physics entry
  ///
  /// In en, this message translates to:
  /// **'Sheet Physics'**
  String get uiSettingsSheetPhysicsTitle;

  /// Subtitle for the sheet physics entry
  ///
  /// In en, this message translates to:
  /// **'Adjust bottom sheet motion physics'**
  String get uiSettingsSheetPhysicsSubtitle;

  /// Chip label for hammer sheet physics
  ///
  /// In en, this message translates to:
  /// **'Hammer'**
  String get uiSettingsSheetPhysicsHammer;

  /// Chip label for slide-up sheet physics
  ///
  /// In en, this message translates to:
  /// **'Slide Up'**
  String get uiSettingsSheetPhysicsSlideUp;

  /// Title for the home header style entry
  ///
  /// In en, this message translates to:
  /// **'Header Style'**
  String get uiSettingsHeaderStyleTitle;

  /// Subtitle for the home header style entry
  ///
  /// In en, this message translates to:
  /// **'Choose the home header layout'**
  String get uiSettingsHeaderStyleSubtitle;

  /// Title for the media card style entry
  ///
  /// In en, this message translates to:
  /// **'Card Style'**
  String get uiSettingsCardStyleTitle;

  /// Subtitle for the media card style entry
  ///
  /// In en, this message translates to:
  /// **'Style of media cards on Home & Discover'**
  String get uiSettingsCardStyleSubtitle;

  /// Title for the continue watching style entry
  ///
  /// In en, this message translates to:
  /// **'Continue Watching Style'**
  String get uiSettingsContinueWatchingTitle;

  /// Subtitle for the continue watching style entry
  ///
  /// In en, this message translates to:
  /// **'Style of cards on the Continue Watching row'**
  String get uiSettingsContinueWatchingSubtitle;

  /// Title for the continue reading style entry
  ///
  /// In en, this message translates to:
  /// **'Continue Reading Style'**
  String get uiSettingsContinueReadingTitle;

  /// Subtitle for the continue reading style entry
  ///
  /// In en, this message translates to:
  /// **'Style of cards on the Continue Reading row'**
  String get uiSettingsContinueReadingSubtitle;

  /// Title for the episode / chapter layout entry
  ///
  /// In en, this message translates to:
  /// **'Episode / Chapter Layout'**
  String get uiSettingsEpisodeViewTitle;

  /// Subtitle for the episode / chapter layout entry
  ///
  /// In en, this message translates to:
  /// **'Default view mode for episode lists'**
  String get uiSettingsEpisodeViewSubtitle;

  /// Title for the navigation bar style entry
  ///
  /// In en, this message translates to:
  /// **'Navigation Bar Style'**
  String get uiSettingsNavBarTitle;

  /// Subtitle for the navigation bar style entry
  ///
  /// In en, this message translates to:
  /// **'Style of the bottom navigation bar'**
  String get uiSettingsNavBarSubtitle;

  /// Section title grouping the color source options
  ///
  /// In en, this message translates to:
  /// **'Color Source'**
  String get settingsColorSource;

  /// Note shown when Dynamic Color manages the color scheme
  ///
  /// In en, this message translates to:
  /// **'Color scheme is managed by Dynamic Color.'**
  String get settingsColorSourceDynamicNote;

  /// Section title grouping the color tweak options
  ///
  /// In en, this message translates to:
  /// **'Color Tweaks'**
  String get settingsColorTweaks;

  /// Subtitle for the Dynamic Color switch
  ///
  /// In en, this message translates to:
  /// **'Uses wallpaper colors'**
  String get settingsDynamicColorSubtitle;

  /// Subtitle for the AMOLED switch
  ///
  /// In en, this message translates to:
  /// **'Saves battery on OLED screens'**
  String get settingsAmoledSubtitle;

  /// Subtitle for the AMOLED switch when it is disabled by a wallpaper
  ///
  /// In en, this message translates to:
  /// **'Disabled while background image is set'**
  String get settingsAmoledDisabledWithWallpaper;

  /// Title for the theme variant / color blend picker entry
  ///
  /// In en, this message translates to:
  /// **'Color Blend'**
  String get settingsThemeVariantTitle;

  /// Subtitle for the theme variant / color blend picker entry
  ///
  /// In en, this message translates to:
  /// **'How system colors are blended into the palette'**
  String get settingsThemeVariantSubtitle;

  /// Title of the theme variant picker sheet
  ///
  /// In en, this message translates to:
  /// **'Color Blend Style'**
  String get settingsThemeStyle;

  /// Title for the Swap Colors switch
  ///
  /// In en, this message translates to:
  /// **'Swap Colors'**
  String get settingsSwapColors;

  /// Subtitle for the Swap Colors switch
  ///
  /// In en, this message translates to:
  /// **'Swap primary and secondary colors'**
  String get settingsSwapColorsSubtitle;

  /// Title of the presets section
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get settingsPresets;

  /// Title of the theme presets gallery entry
  ///
  /// In en, this message translates to:
  /// **'Theme Presets & Gallery'**
  String get settingsThemePresetsTitle;

  /// Subtitle of the theme presets gallery entry
  ///
  /// In en, this message translates to:
  /// **'Explore themes & import/export JSON presets'**
  String get settingsThemePresetsSubtitle;

  /// Title of the exclusive themes shelf
  ///
  /// In en, this message translates to:
  /// **'Exclusive Themes'**
  String get settingsExclusiveThemes;

  /// Title of the standard color schemes shelf or picker
  ///
  /// In en, this message translates to:
  /// **'Standard Color Schemes'**
  String get settingsStandardSchemes;

  /// Title of the exclusive color schemes picker sheet
  ///
  /// In en, this message translates to:
  /// **'Exclusive Color Schemes'**
  String get settingsExclusiveSchemes;

  /// Title of the top generated schemes shelf
  ///
  /// In en, this message translates to:
  /// **'Top Generated Schemes'**
  String get settingsTopGeneratedSchemes;

  /// Subtitle for Check for Updates in About screen
  ///
  /// In en, this message translates to:
  /// **'Update settings and pre-release options'**
  String get aboutCheckUpdatesSubtitle;

  /// Subtitle for GitHub link in About screen
  ///
  /// In en, this message translates to:
  /// **'Source code and releases'**
  String get aboutGithubSubtitle;

  /// Subtitle for Discord link in About screen
  ///
  /// In en, this message translates to:
  /// **'Join the community'**
  String get aboutDiscordSubtitle;

  /// Subtitle for Report an Issue in About screen
  ///
  /// In en, this message translates to:
  /// **'Found a bug? Let us know'**
  String get aboutReportIssueSubtitle;

  /// Loading contributors text
  ///
  /// In en, this message translates to:
  /// **'Loading contributors...'**
  String get aboutLoadingContributors;

  /// Failed to load contributors text
  ///
  /// In en, this message translates to:
  /// **'Failed to load contributors'**
  String get aboutFailedContributors;

  /// Number of contributions for a GitHub contributor
  ///
  /// In en, this message translates to:
  /// **'{count} contributions'**
  String aboutContributionsCount(String count);

  /// Snackbar when addon updates are available
  ///
  /// In en, this message translates to:
  /// **'Updates available for addons.'**
  String get addonsUpdatesAvailable;

  /// Snackbar when all addons are up to date
  ///
  /// In en, this message translates to:
  /// **'All addons are up to date.'**
  String get addonsUpToDate;

  /// Snackbar when checking addon updates fails
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates: {error}'**
  String addonsCheckFailed(String error);

  /// Snackbar when addon download is already running
  ///
  /// In en, this message translates to:
  /// **'Download in progress...'**
  String get addonsDownloadInProgress;

  /// Snackbar when installing an addon fails
  ///
  /// In en, this message translates to:
  /// **'Failed to install {name}: {error}'**
  String addonsInstallFailed(String error, String name);

  /// Dialog text when an addon has an update
  ///
  /// In en, this message translates to:
  /// **'An update is available for {name}.'**
  String addonsUpdateAvailableDialog(String name);

  /// Dialog text when an addon is installed and active
  ///
  /// In en, this message translates to:
  /// **'{name} is installed and active.'**
  String addonsInstalledActiveDialog(String name);

  /// Update button label
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get addonsActionUpdate;

  /// Uninstall button label
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get addonsActionUninstall;

  /// Install button label
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get addonsActionInstall;

  /// Installed status label
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get addonsActionInstalled;

  /// Snackbar when updating an addon fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update {name}: {error}'**
  String addonsUpdateFailed(String error, String name);

  /// Snackbar when an addon is uninstalled
  ///
  /// In en, this message translates to:
  /// **'Uninstalled {name}'**
  String addonsUninstalled(String name);

  /// Snackbar when uninstalling an addon fails
  ///
  /// In en, this message translates to:
  /// **'Failed to uninstall {name}: {error}'**
  String addonsUninstallFailed(String error, String name);

  /// Section title for available addons
  ///
  /// In en, this message translates to:
  /// **'Available Addons'**
  String get addonsAvailableSection;

  /// Message when no addons are registered
  ///
  /// In en, this message translates to:
  /// **'No addons registered.'**
  String get addonsNoneRegistered;

  /// Section title for addon maintenance
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get addonsMaintenanceSection;

  /// Subtitle for checking addon updates
  ///
  /// In en, this message translates to:
  /// **'Scan for new versions of installed addons'**
  String get addonsCheckUpdatesSubtitle;

  /// Heading for cache storage usage
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get cacheStorageUsage;

  /// Text showing used MB out of max cache size
  ///
  /// In en, this message translates to:
  /// **'{used} MB used out of {total}'**
  String cacheUsedOutOf(String total, String used);

  /// Label indicating Isar database storage is active
  ///
  /// In en, this message translates to:
  /// **'Isar Database storage active'**
  String get cacheIsarActive;

  /// Section title for caching settings
  ///
  /// In en, this message translates to:
  /// **'Caching Settings'**
  String get cacheSectionTitle;

  /// Switch title for enabling HTTP caching
  ///
  /// In en, this message translates to:
  /// **'Enable HTTP Caching'**
  String get cacheEnableHttp;

  /// Switch subtitle for HTTP caching
  ///
  /// In en, this message translates to:
  /// **'Cache network responses to load pages faster and save data.'**
  String get cacheEnableHttpSubtitle;

  /// Switch title for bypassing cache
  ///
  /// In en, this message translates to:
  /// **'Bypass Cache (Force Refresh)'**
  String get cacheBypassTitle;

  /// Switch subtitle for bypassing cache
  ///
  /// In en, this message translates to:
  /// **'Forces network fetching, bypassing cached results on reads.'**
  String get cacheBypassSubtitle;

  /// Section title for global cache actions
  ///
  /// In en, this message translates to:
  /// **'Global Actions'**
  String get cacheGlobalActions;

  /// Subtitle for clearing entire cache
  ///
  /// In en, this message translates to:
  /// **'Delete all cached files and network logs.'**
  String get cacheClearEntireSubtitle;

  /// Section title for episode metadata
  ///
  /// In en, this message translates to:
  /// **'Episode Metadata'**
  String get contentEpisodeMetadata;

  /// Title for episode metadata provider setting
  ///
  /// In en, this message translates to:
  /// **'Episode Metadata Provider'**
  String get contentEpisodeMetadataProvider;

  /// Title for available metadata providers group
  ///
  /// In en, this message translates to:
  /// **'Available Providers'**
  String get contentAvailableProviders;

  /// Subtitle for available metadata providers group
  ///
  /// In en, this message translates to:
  /// **'Select which provider enriches episode titles and thumbnails.'**
  String get contentAvailableProvidersSubtitle;

  /// Auto metadata provider title
  ///
  /// In en, this message translates to:
  /// **'Auto (Recommended)'**
  String get contentProviderAutoTitle;

  /// Tenrai metadata provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Official titles, air dates & thumbnails from MyAnimeList'**
  String get contentProviderTenraiSubtitle;

  /// Kitsu metadata provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Community titles, synopses & preview thumbnails'**
  String get contentProviderKitsuSubtitle;

  /// AniZip metadata provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Fast titles & synopses from AniList / MAL'**
  String get contentProviderAnizipSubtitle;

  /// Disabled label
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get contentProviderDisabled;

  /// Disabled metadata provider subtitle
  ///
  /// In en, this message translates to:
  /// **'Raw stream titles without external metadata'**
  String get contentProviderDisabledSubtitle;

  /// Black reader background option
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get readerBgBlack;

  /// Dark grey reader background option
  ///
  /// In en, this message translates to:
  /// **'Dark Grey'**
  String get readerBgDarkGrey;

  /// White reader background option
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get readerBgWhite;

  /// Page transition setting title
  ///
  /// In en, this message translates to:
  /// **'Page Transition'**
  String get readerPageTransition;

  /// Section title for reader controls and behavior
  ///
  /// In en, this message translates to:
  /// **'Controls & Behavior'**
  String get readerControlsBehavior;

  /// Mini status pill switch title
  ///
  /// In en, this message translates to:
  /// **'Mini Status Pill'**
  String get readerMiniStatusPill;

  /// Mini status pill switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Show page number & progress when controls are hidden'**
  String get readerMiniStatusPillSubtitle;

  /// Tap to turn pages switch title
  ///
  /// In en, this message translates to:
  /// **'Tap to Turn Pages'**
  String get readerTapToTurnPages;

  /// Tap to turn pages switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap screen edges to turn pages, center to show controls'**
  String get readerTapToTurnPagesSubtitle;

  /// Keep screen awake switch title
  ///
  /// In en, this message translates to:
  /// **'Keep Screen Awake'**
  String get readerKeepScreenAwake;

  /// Keep screen awake switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Prevent display from sleeping while reading'**
  String get readerKeepScreenAwakeSubtitle;

  /// Section title for system permissions
  ///
  /// In en, this message translates to:
  /// **'System Permissions'**
  String get permissionsSystemSection;

  /// Permission status checking
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get permissionsChecking;

  /// Permission status granted
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionsGranted;

  /// Permission status denied
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permissionsDenied;

  /// Permission status permanently denied
  ///
  /// In en, this message translates to:
  /// **'Denied (Locked)'**
  String get permissionsDeniedLocked;

  /// Permission status restricted
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get permissionsRestricted;

  /// Subtitle for notification permission
  ///
  /// In en, this message translates to:
  /// **'Push notifications and episode release reminders'**
  String get permissionsNotifSubtitle;

  /// Title for ignore battery optimizations permission
  ///
  /// In en, this message translates to:
  /// **'Ignore Battery Optimizations'**
  String get permissionsBatteryTitle;

  /// Subtitle for ignore battery optimizations permission
  ///
  /// In en, this message translates to:
  /// **'Keep downloads running when app is in background or recent apps'**
  String get permissionsBatterySubtitle;

  /// Title for exact alarms permission
  ///
  /// In en, this message translates to:
  /// **'Exact Alarms (Android 12+)'**
  String get permissionsExactAlarmsTitle;

  /// Subtitle for exact alarms permission
  ///
  /// In en, this message translates to:
  /// **'Scheduling precise airing reminders without system delays'**
  String get permissionsExactAlarmsSubtitle;

  /// Title for legacy storage permission
  ///
  /// In en, this message translates to:
  /// **'Storage (Android 10 and below)'**
  String get permissionsStorageLegacyTitle;

  /// Subtitle for legacy storage permission
  ///
  /// In en, this message translates to:
  /// **'Save downloads on older Android versions'**
  String get permissionsStorageLegacySubtitle;

  /// Title for manage external storage permission
  ///
  /// In en, this message translates to:
  /// **'Manage External Storage (Android 11+)'**
  String get permissionsManageStorageTitle;

  /// Subtitle for manage external storage permission
  ///
  /// In en, this message translates to:
  /// **'Save downloads to custom directories across device'**
  String get permissionsManageStorageSubtitle;

  /// Footnote explaining permanently denied permissions
  ///
  /// In en, this message translates to:
  /// **'If a permission is permanently denied, tapping on it will open the app settings where you can manually grant the permission.'**
  String get permissionsPermanentlyDeniedNote;

  /// Title for notifications settings screen
  ///
  /// In en, this message translates to:
  /// **'Manage Anime Notifications'**
  String get notificationsManageTitle;

  /// Empty state title for notifications
  ///
  /// In en, this message translates to:
  /// **'No Subscriptions Yet'**
  String get notificationsEmptyTitle;

  /// Empty state subtitle for notifications
  ///
  /// In en, this message translates to:
  /// **'You can enable notifications for upcoming episodes directly from the anime details page.'**
  String get notificationsEmptySubtitle;

  /// Heading for upcoming notifications
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get notificationsUpcoming;

  /// Heading for all notification subscriptions
  ///
  /// In en, this message translates to:
  /// **'All Subscriptions'**
  String get notificationsAllSubscriptions;

  /// Subscription mode label for entire season
  ///
  /// In en, this message translates to:
  /// **'Following Season'**
  String get notificationsFollowingSeason;

  /// Subscription mode label for next episode
  ///
  /// In en, this message translates to:
  /// **'Following Next Episode'**
  String get notificationsFollowingNextEp;

  /// Next reminder timestamp label
  ///
  /// In en, this message translates to:
  /// **'Next reminder: {time}'**
  String notificationsNextReminder(String time);

  /// Bottom sheet title for source settings
  ///
  /// In en, this message translates to:
  /// **'{name} Settings'**
  String sourceSettingsTitle(String name);

  /// Subtitle when proxy setting is inactive due to in-app CF bypass
  ///
  /// In en, this message translates to:
  /// **'Inactive (In-app Cloudflare Bypass is enabled)'**
  String get sourceSettingsCfInactive;

  /// Default fallback value label
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sourceSettingsDefault;

  /// Snackbar when tapping disabled proxy setting
  ///
  /// In en, this message translates to:
  /// **'Disable \"In-app Cloudflare Bypass\" to use a custom proxy.'**
  String get sourceSettingsCfDisableHint;

  /// Snackbar when trying to uncheck last multi-select option
  ///
  /// In en, this message translates to:
  /// **'At least one option must be selected.'**
  String get sourceSettingsMinOneOption;

  /// Snackbar when already on latest version
  ///
  /// In en, this message translates to:
  /// **'You are using the latest version!'**
  String get updatesLatestVersion;

  /// Section title for Linux updater
  ///
  /// In en, this message translates to:
  /// **'Linux Installation & Updater'**
  String get updatesLinuxSection;

  /// Tile title to open Linux update manager
  ///
  /// In en, this message translates to:
  /// **'Open Linux Update Manager'**
  String get updatesLinuxOpenTitle;

  /// Tile subtitle for Linux update manager
  ///
  /// In en, this message translates to:
  /// **'Interactive installer, custom repo/icon config, and live terminal output'**
  String get updatesLinuxOpenSubtitle;

  /// Tile title for manual update check
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get updatesCheckNow;

  /// Tile subtitle for manual update check
  ///
  /// In en, this message translates to:
  /// **'Fetch the latest releases directly from GitHub'**
  String get updatesCheckNowSubtitle;

  /// Button label to check updates
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get updatesCheckButton;

  /// Section title for update preferences
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get updatesPreferences;

  /// Switch title for including pre-releases
  ///
  /// In en, this message translates to:
  /// **'Include Pre-releases'**
  String get updatesIncludePrerelease;

  /// Switch subtitle for including pre-releases
  ///
  /// In en, this message translates to:
  /// **'Receive early builds marked as pre-release on GitHub'**
  String get updatesIncludePrereleaseSubtitle;

  /// Switch title for auto check on startup
  ///
  /// In en, this message translates to:
  /// **'Auto Check on Startup'**
  String get updatesAutoCheck;

  /// Switch subtitle for auto check on startup
  ///
  /// In en, this message translates to:
  /// **'Automatically check for updates when the application launches'**
  String get updatesAutoCheckSubtitle;

  /// Section title for browsing GitHub releases
  ///
  /// In en, this message translates to:
  /// **'Browse Releases'**
  String get updatesBrowseReleases;

  /// Section subtitle for browsing releases
  ///
  /// In en, this message translates to:
  /// **'Tap a release to view full changelog and download options'**
  String get updatesBrowseReleasesSubtitle;

  /// Error text when releases fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load releases.'**
  String get updatesLoadFailed;

  /// Empty text when no releases found
  ///
  /// In en, this message translates to:
  /// **'No releases found.'**
  String get updatesNoneFound;

  /// Snackbar when exporting without selected categories
  ///
  /// In en, this message translates to:
  /// **'Select at least one category to export'**
  String get backupSelectAtLeastOne;

  /// Dialog title when saving backup
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get backupSaveDialogTitle;

  /// Snackbar when backup is saved
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// Snackbar when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String backupExportFailed(String error);

  /// Snackbar when picked backup file is empty
  ///
  /// In en, this message translates to:
  /// **'Backup file is empty'**
  String get backupFileEmpty;

  /// Snackbar when backup file has no valid data
  ///
  /// In en, this message translates to:
  /// **'No valid backup data found in file'**
  String get backupNoValidData;

  /// Snackbar when backup file is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file: {error}'**
  String backupInvalidFile(String error);

  /// Section title for restoring backup
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreSection;

  /// Section subtitle for restoring backup
  ///
  /// In en, this message translates to:
  /// **'Import data from a previously exported backup file'**
  String get backupRestoreSectionSubtitle;

  /// Tile title for restoring from file
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get backupRestoreFromFile;

  /// Tile subtitle for restoring from file
  ///
  /// In en, this message translates to:
  /// **'Select a .json backup file to inspect and restore'**
  String get backupRestoreFromFileSubtitle;

  /// Section title for exporting backup
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get backupExportSection;

  /// Section subtitle for exporting backup
  ///
  /// In en, this message translates to:
  /// **'Choose what to include in your backup file'**
  String get backupExportSectionSubtitle;

  /// Count of local records in backup screen
  ///
  /// In en, this message translates to:
  /// **'{count} local records'**
  String backupLocalRecordsCount(String count);

  /// Button label while exporting
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get backupExporting;

  /// Button label to save backup
  ///
  /// In en, this message translates to:
  /// **'Save Backup'**
  String get backupSaveBackup;

  /// Tooltip for sharing backup
  ///
  /// In en, this message translates to:
  /// **'Share Backup'**
  String get backupShareBackup;

  /// Title for import preview screen
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get backupImportPreviewTitle;

  /// Snackbar when backup is restored
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backupRestoredSuccess;

  /// Snackbar when backup import fails
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String backupImportFailed(String error);

  /// Warning text on import preview screen
  ///
  /// In en, this message translates to:
  /// **'Importing will replace existing data for selected categories.'**
  String get backupImportWarning;

  /// Section title for backup categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get backupCategoriesSection;

  /// Tile title to confirm backup import
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get backupConfirmImport;

  /// Subtitle while importing backup
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get backupImporting;

  /// Subtitle showing number of selected categories
  ///
  /// In en, this message translates to:
  /// **'{count} categories selected'**
  String backupCategoriesSelected(String count);

  /// Subtitle showing incoming items replacing existing items
  ///
  /// In en, this message translates to:
  /// **'{incoming} items → replaces {existing} existing'**
  String backupItemsReplace(String existing, String incoming);

  /// Subtitle showing incoming items count
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String backupItemsCount(String count);

  /// Section title for download organization
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get downloadOrganizationSection;

  /// Switch title for creating anime subfolders
  ///
  /// In en, this message translates to:
  /// **'Create Anime Folders'**
  String get downloadCreateSubfolders;

  /// Switch subtitle for creating anime subfolders
  ///
  /// In en, this message translates to:
  /// **'Groups episodes inside a folder named after the anime title'**
  String get downloadCreateSubfoldersSubtitle;

  /// Dropdown title for file name format
  ///
  /// In en, this message translates to:
  /// **'File Name Format'**
  String get downloadFileNameFormat;

  /// Preview label for file name format
  ///
  /// In en, this message translates to:
  /// **'↳ Preview: {preview}'**
  String downloadPreviewFormat(String preview);

  /// Section title for download network & integration
  ///
  /// In en, this message translates to:
  /// **'Network & Integration'**
  String get downloadNetworkSection;

  /// Switch title for Wi-Fi only downloads
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi Only'**
  String get downloadWifiOnly;

  /// Switch subtitle for Wi-Fi only downloads
  ///
  /// In en, this message translates to:
  /// **'Pause downloads when connected to mobile data'**
  String get downloadWifiOnlySubtitle;

  /// Title for using external 1DM downloader
  ///
  /// In en, this message translates to:
  /// **'Use External Downloader (1DM)'**
  String get downloadUseOneDm;

  /// Subtitle when 1DM is installed
  ///
  /// In en, this message translates to:
  /// **'Send links to external apps instead of the built-in engine'**
  String get downloadUseOneDmSubtitle;

  /// Subtitle when 1DM is not installed
  ///
  /// In en, this message translates to:
  /// **'1DM is not installed on your device. High-speed multi-threaded downloader for Android.'**
  String get downloadOneDmNotInstalled;

  /// Tooltip for 1DM info button
  ///
  /// In en, this message translates to:
  /// **'What is 1DM?'**
  String get downloadWhatIsOneDm;

  /// Dialog title about 1DM
  ///
  /// In en, this message translates to:
  /// **'About 1DM Downloader'**
  String get downloadAboutOneDmTitle;

  /// Dialog body explaining 1DM
  ///
  /// In en, this message translates to:
  /// **'1DM (Internet Download Manager) is a popular third-party Android download manager app. It supports up to 32 parallel download connections, background downloads, and smart error recovery.\n\nIf installed, ShonenX can send episode download streams directly to 1DM.'**
  String get downloadAboutOneDmBody;

  /// Button label to open Play Store
  ///
  /// In en, this message translates to:
  /// **'Get on Play Store'**
  String get downloadGetOnPlayStore;

  /// Section title for download performance tweaks
  ///
  /// In en, this message translates to:
  /// **'Performance Tweaks'**
  String get downloadPerformanceSection;

  /// Slider title for max concurrent downloads
  ///
  /// In en, this message translates to:
  /// **'Max Queue (Concurrent Downloads)'**
  String get downloadMaxQueue;

  /// Slider subtitle for max concurrent downloads
  ///
  /// In en, this message translates to:
  /// **'Maximum active downloads at a time'**
  String get downloadMaxQueueSubtitle;

  /// Slider title for max concurrent HLS segments
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Segments (HLS)'**
  String get downloadMaxSegments;

  /// Slider subtitle for max concurrent HLS segments
  ///
  /// In en, this message translates to:
  /// **'Parallel threads for stream segments'**
  String get downloadMaxSegmentsSubtitle;

  /// Dropdown title for HLS remuxer preference
  ///
  /// In en, this message translates to:
  /// **'HLS Remuxer Preference'**
  String get downloadRemuxerPref;

  /// Snackbar when download location changed
  ///
  /// In en, this message translates to:
  /// **'Download location changed successfully.'**
  String get downloadLocationChanged;

  /// Sheet title for reviewing files to move
  ///
  /// In en, this message translates to:
  /// **'Review Files to Move'**
  String get downloadReviewFilesTitle;

  /// Label showing target path for moving files
  ///
  /// In en, this message translates to:
  /// **'Moving to:\n{path}'**
  String downloadMovingTo(String path);

  /// Count of selected files out of total
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String downloadSelectedOfTotal(String selected, String total);

  /// Snackbar when files are moved
  ///
  /// In en, this message translates to:
  /// **'Moved {count} files and updated location.'**
  String downloadMovedFiles(String count);

  /// Button label to move selected files and change location
  ///
  /// In en, this message translates to:
  /// **'Move Selected ({count}) & Change Location'**
  String downloadMoveSelectedBtn(String count);

  /// Snackbar when location changed without moving files
  ///
  /// In en, this message translates to:
  /// **'Changed location without moving files.'**
  String get downloadChangedLocationOnly;

  /// Button label to change location without moving files
  ///
  /// In en, this message translates to:
  /// **'Change Location Only (Don\'t Move Any)'**
  String get downloadChangeLocationOnlyBtn;

  /// Banner title when app lock is active
  ///
  /// In en, this message translates to:
  /// **'App Lock is Active'**
  String get securityAppLockActive;

  /// Banner title when app lock is disabled
  ///
  /// In en, this message translates to:
  /// **'App Lock is Disabled'**
  String get securityAppLockDisabled;

  /// Banner subtitle when protected with PIN and biometrics
  ///
  /// In en, this message translates to:
  /// **'Protected with PIN & Biometrics'**
  String get securityProtectedPinBio;

  /// Banner subtitle when protected with 4-digit PIN
  ///
  /// In en, this message translates to:
  /// **'Protected with 4-digit PIN'**
  String get securityProtectedPin;

  /// Banner subtitle prompting to set up a PIN
  ///
  /// In en, this message translates to:
  /// **'Set up a PIN to protect your data.'**
  String get securitySetupPinPrompt;

  /// Section title for app lock
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get securityAppLockSection;

  /// Switch title to enable app lock
  ///
  /// In en, this message translates to:
  /// **'Enable App Lock'**
  String get securityEnableAppLock;

  /// Switch subtitle to enable app lock
  ///
  /// In en, this message translates to:
  /// **'Require authentication to open ShonenX'**
  String get securityEnableAppLockSubtitle;

  /// Title when disabling app lock
  ///
  /// In en, this message translates to:
  /// **'Disable App Lock'**
  String get securityDisableAppLock;

  /// Subtitle when disabling app lock
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to turn off app lock'**
  String get securityDisableAppLockSubtitle;

  /// Tile title to change PIN
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePin;

  /// Tile subtitle to change PIN
  ///
  /// In en, this message translates to:
  /// **'Update your 4-digit security PIN'**
  String get securityChangePinSubtitle;

  /// Snackbar when PIN is updated
  ///
  /// In en, this message translates to:
  /// **'PIN updated successfully'**
  String get securityPinUpdated;

  /// Switch title for biometric unlock
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get securityBiometricUnlock;

  /// Biometric prompt reason when enabling
  ///
  /// In en, this message translates to:
  /// **'Confirm biometrics to enable unlock'**
  String get securityConfirmBiometricsReason;

  /// Switch title for auto-prompt biometrics
  ///
  /// In en, this message translates to:
  /// **'Auto-prompt Biometrics'**
  String get securityAutoPromptBiometrics;

  /// Switch subtitle for auto-prompt biometrics
  ///
  /// In en, this message translates to:
  /// **'Immediately show prompt when opening app'**
  String get securityAutoPromptBiometricsSubtitle;

  /// Dropdown title for auto-lock timeout
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get securityAutoLockTimeout;

  /// Section title for privacy
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get securityPrivacySection;

  /// Title for incognito mode
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get securityIncognitoMode;

  /// Subtitle for incognito mode
  ///
  /// In en, this message translates to:
  /// **'Pause watch history, read history, and cloud tracking'**
  String get securityIncognitoSubtitle;

  /// Heading inside incognito info sheet
  ///
  /// In en, this message translates to:
  /// **'Private Viewing & Reading'**
  String get securityIncognitoSheetHeading;

  /// Body inside incognito info sheet
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode prevents ShonenX from saving your watch progress, read history, or syncing activity to your connected trackers (MAL, AniList, etc.).'**
  String get securityIncognitoSheetBody;

  /// Highlighted note inside incognito info sheet
  ///
  /// In en, this message translates to:
  /// **'Watch history, read chapters, and cloud tracker updates are paused until disabled.'**
  String get securityIncognitoSheetPauseNote;

  /// Footer note inside incognito info sheet
  ///
  /// In en, this message translates to:
  /// **'Your tracker accounts and existing history remain intact. Normal syncing and history resume when Incognito Mode is turned off.'**
  String get securityIncognitoSheetFooter;

  /// Section title for network and DNS
  ///
  /// In en, this message translates to:
  /// **'Network & DNS'**
  String get securityNetworkDnsSection;

  /// Title for DNS over HTTPS
  ///
  /// In en, this message translates to:
  /// **'DNS over HTTPS (DoH)'**
  String get securityDohTitle;

  /// Section title for quick security actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get securityActionsSection;

  /// Tile title to lock app immediately
  ///
  /// In en, this message translates to:
  /// **'Lock App Now'**
  String get securityLockNow;

  /// Tile subtitle to lock app immediately
  ///
  /// In en, this message translates to:
  /// **'Instantly lock the app to test security'**
  String get securityLockNowSubtitle;

  /// Tile title to reset security settings
  ///
  /// In en, this message translates to:
  /// **'Reset Security Settings'**
  String get securityResetTitle;

  /// Tile subtitle to reset security settings
  ///
  /// In en, this message translates to:
  /// **'Clear PIN and remove all lock preferences'**
  String get securityResetSubtitle;

  /// Confirmation message for resetting security settings
  ///
  /// In en, this message translates to:
  /// **'This will remove your PIN and disable app lock. Are you sure?'**
  String get securityResetConfirmMessage;

  /// Snackbar when security settings are reset
  ///
  /// In en, this message translates to:
  /// **'Security settings reset'**
  String get securitySettingsResetSnack;

  /// Heading inside DoH info sheet
  ///
  /// In en, this message translates to:
  /// **'Encrypted DNS Lookups'**
  String get securityDohSheetHeading;

  /// Body inside DoH info sheet
  ///
  /// In en, this message translates to:
  /// **'DNS over HTTPS (DoH) encrypts all domain name queries via HTTPS to prevent ISP snooping, ISP domain hijacking, and censorship. By default, ShonenX uses Cloudflare DNS (1.1.1.1) for maximum speed and privacy.'**
  String get securityDohSheetBody;

  /// Bullet point for Cloudflare DNS
  ///
  /// In en, this message translates to:
  /// **'• Cloudflare: Fast, zero-logging DNS (1.1.1.1 & 1.0.0.1)'**
  String get securityDohCloudflareNote;

  /// Bullet point for Google DNS
  ///
  /// In en, this message translates to:
  /// **'• Google: Highly reliable global resolver (8.8.8.8 & 8.8.4.4)'**
  String get securityDohGoogleNote;

  /// Bullet point for System DNS
  ///
  /// In en, this message translates to:
  /// **'• System: Bypasses DoH and uses standard device DNS'**
  String get securityDohSystemNote;

  /// Snackbar when DNS cache is flushed
  ///
  /// In en, this message translates to:
  /// **'DNS cache flushed successfully'**
  String get securityDnsCacheFlushed;

  /// Button label while testing DNS
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get securityTestingDns;

  /// Button label to test DNS resolution
  ///
  /// In en, this message translates to:
  /// **'Test DNS Resolution'**
  String get securityTestDns;

  /// Tooltip to flush DNS cache
  ///
  /// In en, this message translates to:
  /// **'Flush DNS Cache'**
  String get securityFlushDnsCache;

  /// Title when DNS test fails
  ///
  /// In en, this message translates to:
  /// **'Test Failed'**
  String get securityTestFailed;

  /// Label showing resolved DNS IP addresses
  ///
  /// In en, this message translates to:
  /// **'Resolved to: {addresses}'**
  String securityResolvedTo(String addresses);

  /// Sheet title to customize idle Discord RPC status
  ///
  /// In en, this message translates to:
  /// **'Customize Idle RPC Status'**
  String get discordEditIdleTitle;

  /// TextField label for Discord activity name
  ///
  /// In en, this message translates to:
  /// **'Activity Name'**
  String get discordActivityName;

  /// TextField label for Discord details/subtitle
  ///
  /// In en, this message translates to:
  /// **'Details / Subtitle'**
  String get discordDetailsSubtitle;

  /// Button label to save changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get discordSaveChanges;

  /// Dialog title to disconnect Discord account
  ///
  /// In en, this message translates to:
  /// **'Disconnect Discord Account'**
  String get discordDisconnectTitle;

  /// Dialog message to disconnect Discord account
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your Discord account? Your saved account token will be removed.'**
  String get discordDisconnectMessage;

  /// Button label to disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get discordDisconnectAction;

  /// Fallback display name for Discord user
  ///
  /// In en, this message translates to:
  /// **'Discord User'**
  String get discordUserFallback;

  /// Status label when Discord RPC is active and synced
  ///
  /// In en, this message translates to:
  /// **'Active & Synced'**
  String get discordActiveSynced;

  /// Status label when Discord is connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get discordConnected;

  /// Tooltip to refresh Discord profile
  ///
  /// In en, this message translates to:
  /// **'Refresh Profile'**
  String get discordRefreshProfile;

  /// Title in Discord card when logged out
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence'**
  String get discordRichPresenceTitle;

  /// Subtitle in Discord card when logged out
  ///
  /// In en, this message translates to:
  /// **'Share your watch & read activity'**
  String get discordShareActivity;

  /// Info note about Discord desktop vs token login
  ///
  /// In en, this message translates to:
  /// **'Desktop users connect automatically via the running Discord app. Signing in with a user token is optional (for mobile/gateway sync).'**
  String get discordDesktopAutoConnectNote;

  /// Button label to sign in with Discord account
  ///
  /// In en, this message translates to:
  /// **'Sign in with Discord Account'**
  String get discordSignInButton;

  /// Section title for presence control
  ///
  /// In en, this message translates to:
  /// **'Presence Control'**
  String get discordPresenceControl;

  /// Switch title to enable Discord RPC
  ///
  /// In en, this message translates to:
  /// **'Enable Discord RPC'**
  String get discordEnableRpc;

  /// Switch subtitle to enable Discord RPC
  ///
  /// In en, this message translates to:
  /// **'Broadcast anime watching & manga reading activity'**
  String get discordEnableRpcSubtitle;

  /// Section title for activity broadcasting
  ///
  /// In en, this message translates to:
  /// **'Activity Broadcasting'**
  String get discordActivityBroadcasting;

  /// Switch title for showing details screen activity
  ///
  /// In en, this message translates to:
  /// **'Show Details Screen Activity'**
  String get discordShowDetailsActivity;

  /// Switch subtitle for showing details screen activity
  ///
  /// In en, this message translates to:
  /// **'Display \"Viewing {Title}\" when inspecting anime/manga'**
  String discordShowDetailsActivitySubtitle(String Title);

  /// Switch title for showing video player activity
  ///
  /// In en, this message translates to:
  /// **'Show Video Player Activity'**
  String get discordShowPlayerActivity;

  /// Switch subtitle for showing video player activity
  ///
  /// In en, this message translates to:
  /// **'Display \"Watching Episode X\" while playing anime'**
  String get discordShowPlayerActivitySubtitle;

  /// Switch title for showing manga reader activity
  ///
  /// In en, this message translates to:
  /// **'Show Manga Reader Activity'**
  String get discordShowReaderActivity;

  /// Switch subtitle for showing manga reader activity
  ///
  /// In en, this message translates to:
  /// **'Display \"Reading Chapter X\" while reading manga'**
  String get discordShowReaderActivitySubtitle;

  /// Section title for presence customization
  ///
  /// In en, this message translates to:
  /// **'Presence Customization'**
  String get discordPresenceCustomization;

  /// Tile title for idle activity status
  ///
  /// In en, this message translates to:
  /// **'Idle Activity Status'**
  String get discordIdleActivityStatus;

  /// Switch title for showing episode/chapter numbers
  ///
  /// In en, this message translates to:
  /// **'Show Episode/Chapter Numbers'**
  String get discordShowEpisodeNumbers;

  /// Switch subtitle for showing episode/chapter numbers
  ///
  /// In en, this message translates to:
  /// **'Include the current episode or chapter number'**
  String get discordShowEpisodeNumbersSubtitle;

  /// Switch title for showing watch/read progress
  ///
  /// In en, this message translates to:
  /// **'Show Watch/Read Progress'**
  String get discordShowProgress;

  /// Switch subtitle for showing watch/read progress
  ///
  /// In en, this message translates to:
  /// **'Display elapsed time and page progress'**
  String get discordShowProgressSubtitle;

  /// Switch title for showing media cover images
  ///
  /// In en, this message translates to:
  /// **'Show Media Cover Images'**
  String get discordShowMediaImages;

  /// Switch subtitle for showing media cover images
  ///
  /// In en, this message translates to:
  /// **'Display the anime/manga poster in Discord'**
  String get discordShowMediaImagesSubtitle;

  /// Switch title for showing view buttons
  ///
  /// In en, this message translates to:
  /// **'Show View Buttons'**
  String get discordShowViewButtons;

  /// Switch subtitle for showing view buttons
  ///
  /// In en, this message translates to:
  /// **'Add a clickable button to the Anilist page'**
  String get discordShowViewButtonsSubtitle;

  /// Title for home settings screen
  ///
  /// In en, this message translates to:
  /// **'Home Settings'**
  String get homeSettingsTitle;

  /// Banner title when source discovery mode is active
  ///
  /// In en, this message translates to:
  /// **'Source Discovery Mode Active'**
  String get homeSourceModeActive;

  /// Banner description when source discovery mode is active
  ///
  /// In en, this message translates to:
  /// **'Content extensions only support a single Trending feed. Switch to Tracker Discovery Mode to unlock custom categories (Popular, Upcoming, Top Rated).'**
  String get homeSourceModeBannerDesc;

  /// Subtitle for continue media section in home settings
  ///
  /// In en, this message translates to:
  /// **'{mediaType} • Continue Progress'**
  String homeContinueProgressSubtitle(String mediaType);

  /// Fallback tracker label in home settings
  ///
  /// In en, this message translates to:
  /// **'Auto Source'**
  String get homeAutoSource;

  /// Tooltip/title for adding a home section
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get homeAddSection;

  /// Sheet title for editing a home section
  ///
  /// In en, this message translates to:
  /// **'Edit Section'**
  String get homeEditSection;

  /// Sheet title for section options
  ///
  /// In en, this message translates to:
  /// **'Section Options'**
  String get homeSectionOptions;

  /// Dropdown label for section type
  ///
  /// In en, this message translates to:
  /// **'Section Type'**
  String get homeSectionType;

  /// Section type label for discovery feed
  ///
  /// In en, this message translates to:
  /// **'Discovery Feed'**
  String get homeDiscoveryFeed;

  /// Section type label for continue progress
  ///
  /// In en, this message translates to:
  /// **'Continue Progress'**
  String get homeContinueProgress;

  /// Section type label for library list
  ///
  /// In en, this message translates to:
  /// **'Library List'**
  String get homeLibraryList;

  /// Suffix when all items of a section type are already added
  ///
  /// In en, this message translates to:
  /// **' (All added)'**
  String get homeAllAdded;

  /// Suffix when continue progress section is already added
  ///
  /// In en, this message translates to:
  /// **' (Already added)'**
  String get homeAlreadyAdded;

  /// Dropdown label for media type
  ///
  /// In en, this message translates to:
  /// **'Media Type'**
  String get homeMediaType;

  /// Dropdown label for category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get homeCategory;

  /// Helper text when categories are locked in source discovery mode
  ///
  /// In en, this message translates to:
  /// **'Categories are locked to Trending in Source Discovery Mode.'**
  String get homeCategoriesLockedHelper;

  /// Dropdown label for library list status
  ///
  /// In en, this message translates to:
  /// **'List to Display'**
  String get homeListToDisplay;

  /// Dropdown label for data source
  ///
  /// In en, this message translates to:
  /// **'Data Source'**
  String get homeDataSource;

  /// Dropdown item for auto default data source
  ///
  /// In en, this message translates to:
  /// **'Auto (Default)'**
  String get homeAutoDefault;

  /// TextField label for section title
  ///
  /// In en, this message translates to:
  /// **'Section Title'**
  String get homeSectionTitle;

  /// Auto title prefix for library status section
  ///
  /// In en, this message translates to:
  /// **'My {status}'**
  String homeMyStatusPrefix(String status);

  /// Title for tracking & sync screen
  ///
  /// In en, this message translates to:
  /// **'Tracking & Sync'**
  String get trackingSyncTitle;

  /// Dialog title for tracker API credentials
  ///
  /// In en, this message translates to:
  /// **'{tracker} Credentials'**
  String trackingCredentialsTitle(String tracker);

  /// Dialog description for custom tracker credentials
  ///
  /// In en, this message translates to:
  /// **'Provide your own API Client ID and Secret. This overrides the default bundled credentials.\nLeave blank or click Reset to use the default credentials.'**
  String get trackingCredentialsBody;

  /// Label showing active redirect URI
  ///
  /// In en, this message translates to:
  /// **'Active Redirect URI ({mode} mode):'**
  String trackingActiveRedirectUri(String mode);

  /// TextField label for Client ID
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get trackingClientId;

  /// TextField label for Client Secret
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get trackingClientSecret;

  /// TextField hint to leave empty for default
  ///
  /// In en, this message translates to:
  /// **'Leave empty for default'**
  String get trackingLeaveEmptyDefault;

  /// Snackbar when custom credentials are reset
  ///
  /// In en, this message translates to:
  /// **'Reset {tracker} credentials to default'**
  String trackingCredentialsResetSnack(String tracker);

  /// Title for OAuth authentication method
  ///
  /// In en, this message translates to:
  /// **'OAuth Authentication Method'**
  String get trackingOAuthMethod;

  /// OAuth mode Auto
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get trackingAuthAuto;

  /// OAuth mode Browser
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get trackingAuthBrowser;

  /// OAuth mode WebView
  ///
  /// In en, this message translates to:
  /// **'WebView'**
  String get trackingAuthWebview;

  /// Slider title for sync threshold
  ///
  /// In en, this message translates to:
  /// **'Sync Threshold'**
  String get trackingSyncThreshold;

  /// Slider subtitle for sync threshold
  ///
  /// In en, this message translates to:
  /// **'Mark episode as watched after {percent}% runtime'**
  String trackingSyncThresholdSubtitle(String percent);

  /// Section title for tracking automation
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get trackingAutomationSection;

  /// Switch title for auto-link trackers
  ///
  /// In en, this message translates to:
  /// **'Auto-Link Trackers'**
  String get trackingAutoLink;

  /// Switch subtitle for auto-link trackers
  ///
  /// In en, this message translates to:
  /// **'Automatically create mappings with active trackers when matching IDs are found'**
  String get trackingAutoLinkSubtitle;

  /// Heading inside auto-link info sheet
  ///
  /// In en, this message translates to:
  /// **'Automatically connect tracker entries'**
  String get trackingAutoLinkSheetHeading;

  /// Body inside auto-link info sheet
  ///
  /// In en, this message translates to:
  /// **'Normally you need to manually link anime and manga to your trackers. With Auto-Link Trackers enabled, ShonenX automatically creates mappings with your active trackers whenever matching IDs are found.'**
  String get trackingAutoLinkSheetBody;

  /// Highlighted box inside auto-link info sheet
  ///
  /// In en, this message translates to:
  /// **'If a media is already in your cloud tracker library, its status and progress will appear instantly without manual linking. Watched episodes and read chapters will also sync progress automatically.'**
  String get trackingAutoLinkSheetHighlight;

  /// Bold prefix for best results tip
  ///
  /// In en, this message translates to:
  /// **'Best results: '**
  String get trackingBestResultsPrefix;

  /// Body for best results tip
  ///
  /// In en, this message translates to:
  /// **'Use the same service for both your Discovery Source and Primary Tracker (for example, AniList + AniList).'**
  String get trackingBestResultsBody;

  /// Footer note inside auto-link info sheet
  ///
  /// In en, this message translates to:
  /// **'When disabled, tracker mappings will never be created automatically and unlinked media will not sync.'**
  String get trackingAutoLinkFooter;

  /// Section title for trackers list
  ///
  /// In en, this message translates to:
  /// **'Trackers'**
  String get trackingTrackersSection;

  /// Guest username label
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get trackingGuest;

  /// Badge suffix for primary tracker
  ///
  /// In en, this message translates to:
  /// **' (Primary)'**
  String get trackingPrimaryBadge;

  /// Status label while logging into tracker
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get trackingLoggingIn;

  /// Subtitle showing logged-in username
  ///
  /// In en, this message translates to:
  /// **'Logged in as {username}'**
  String trackingLoggedInAs(String username);

  /// Subtitle when tracker API credentials are missing
  ///
  /// In en, this message translates to:
  /// **'Missing API Credentials'**
  String get trackingMissingApiCreds;

  /// Subtitle when not logged into tracker
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get trackingNotLoggedIn;

  /// Tooltip for custom API credentials button
  ///
  /// In en, this message translates to:
  /// **'Custom API Credentials'**
  String get trackingCustomApiCredsTooltip;

  /// Button label to add API credentials
  ///
  /// In en, this message translates to:
  /// **'Add Credentials'**
  String get trackingAddCredentials;

  /// Button label to log in
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get trackingLogin;

  /// Section title for video engine and preferences
  ///
  /// In en, this message translates to:
  /// **'Video Engine & Preferences'**
  String get playerVideoEngineSection;

  /// Title for Media Kit (MPV) engine
  ///
  /// In en, this message translates to:
  /// **'Media Kit (MPV)'**
  String get playerMediaKitTitle;

  /// Subtitle for Media Kit (MPV) engine
  ///
  /// In en, this message translates to:
  /// **'Standalone player engine with advanced subtitle & shader support'**
  String get playerMediaKitSubtitle;

  /// Title for Better Player (ExoPlayer)
  ///
  /// In en, this message translates to:
  /// **'Better Player (ExoPlayer)'**
  String get playerBetterPlayerTitle;

  /// Subtitle for Better Player (ExoPlayer)
  ///
  /// In en, this message translates to:
  /// **'Official Android native video rendering engine'**
  String get playerBetterPlayerSubtitle;

  /// Section title for playback defaults
  ///
  /// In en, this message translates to:
  /// **'Playback Defaults'**
  String get playerPlaybackDefaultsSection;

  /// Dropdown title for default server type
  ///
  /// In en, this message translates to:
  /// **'Default Server Type (Sub / Dub)'**
  String get playerDefaultServerType;

  /// Server type Any
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get playerServerAny;

  /// Dropdown title for default video quality
  ///
  /// In en, this message translates to:
  /// **'Default Video Quality'**
  String get playerDefaultVideoQuality;

  /// Dropdown item for custom value
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get playerCustomOption;

  /// Dialog title for custom video quality
  ///
  /// In en, this message translates to:
  /// **'Custom Video Quality'**
  String get playerCustomVideoQualityTitle;

  /// Hint for custom video quality input
  ///
  /// In en, this message translates to:
  /// **'e.g. 4K, 2160p, 1440p, 1080p'**
  String get playerCustomVideoQualityHint;

  /// Dropdown title for default audio language
  ///
  /// In en, this message translates to:
  /// **'Default Audio Language'**
  String get playerDefaultAudioLang;

  /// Dialog title for custom audio language
  ///
  /// In en, this message translates to:
  /// **'Custom Audio Language'**
  String get playerCustomAudioLangTitle;

  /// Hint for custom audio language input
  ///
  /// In en, this message translates to:
  /// **'e.g. jpn, eng, spa, de'**
  String get playerCustomAudioLangHint;

  /// Dropdown title for default subtitle language
  ///
  /// In en, this message translates to:
  /// **'Default Subtitle Language'**
  String get playerDefaultSubtitleLang;

  /// Dialog title for custom subtitle language
  ///
  /// In en, this message translates to:
  /// **'Custom Subtitle Language'**
  String get playerCustomSubtitleLangTitle;

  /// Hint for custom subtitle language input
  ///
  /// In en, this message translates to:
  /// **'e.g. eng, spa, ger, ja'**
  String get playerCustomSubtitleLangHint;

  /// Section title for auto-next and quick skip
  ///
  /// In en, this message translates to:
  /// **'Auto-Next & Quick Skip'**
  String get playerAutoNextQuickSkipSection;

  /// Switch title for auto-switching to next episode
  ///
  /// In en, this message translates to:
  /// **'Auto-Switch to Next Episode'**
  String get playerAutoSwitchNextEpisode;

  /// Switch subtitle for auto-switching to next episode
  ///
  /// In en, this message translates to:
  /// **'Automatically load next episode when countdown finishes or video ends'**
  String get playerAutoSwitchNextEpisodeSubtitle;

  /// Dropdown title for next episode prompt threshold
  ///
  /// In en, this message translates to:
  /// **'Next Episode Prompt Threshold'**
  String get playerNextEpisodePromptThreshold;

  /// Dropdown item showing seconds before end
  ///
  /// In en, this message translates to:
  /// **'{seconds}s before end'**
  String playerSecondsBeforeEnd(String seconds);

  /// Switch title for showing quick skip button
  ///
  /// In en, this message translates to:
  /// **'Show Quick Skip Button'**
  String get playerShowQuickSkip;

  /// Switch subtitle for showing quick skip button
  ///
  /// In en, this message translates to:
  /// **'Display quick seek button (+Xs) during playback'**
  String get playerShowQuickSkipSubtitle;

  /// Dropdown title for quick skip duration
  ///
  /// In en, this message translates to:
  /// **'Quick Skip Duration'**
  String get playerQuickSkipDuration;

  /// Section title for subtitles and gestures
  ///
  /// In en, this message translates to:
  /// **'Subtitles & Gestures'**
  String get playerSubtitlesGesturesSection;

  /// Tile and sheet title for subtitle preferences
  ///
  /// In en, this message translates to:
  /// **'Subtitle Preferences'**
  String get playerSubtitlePreferences;

  /// Tile subtitle for subtitle preferences
  ///
  /// In en, this message translates to:
  /// **'Customize subtitle appearance and rendering engine'**
  String get playerSubtitlePreferencesSubtitle;

  /// Tile subtitle for subtitle translation
  ///
  /// In en, this message translates to:
  /// **'Configure AI translation providers, API keys, and auto-translation'**
  String get playerSubtitleTranslationSubtitle;

  /// Tile and sheet title for gesture area
  ///
  /// In en, this message translates to:
  /// **'Gesture Area'**
  String get playerGestureArea;

  /// Tile subtitle for gesture area
  ///
  /// In en, this message translates to:
  /// **'Customize active zones for volume and brightness'**
  String get playerGestureAreaSubtitle;

  /// Switch title for enabling gestures
  ///
  /// In en, this message translates to:
  /// **'Enable Gestures'**
  String get playerEnableGestures;

  /// Switch subtitle for enabling gestures
  ///
  /// In en, this message translates to:
  /// **'Allow swiping to seek, change volume, and brightness'**
  String get playerEnableGesturesSubtitle;

  /// Switch title for swapping volume and brightness gestures
  ///
  /// In en, this message translates to:
  /// **'Swap Volume & Brightness'**
  String get playerSwapVolumeBrightness;

  /// Switch subtitle for swapping volume and brightness gestures
  ///
  /// In en, this message translates to:
  /// **'Place Volume on the left and Brightness on the right'**
  String get playerSwapVolumeBrightnessSubtitle;

  /// Title for extensions/sources screen
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get extensionsSourcesTitle;

  /// Subtitle for extensions/sources screen
  ///
  /// In en, this message translates to:
  /// **'Extensions & Catalogs'**
  String get extensionsCatalogsSubtitle;

  /// Filter label for all extension engines
  ///
  /// In en, this message translates to:
  /// **'All Engines'**
  String get extensionsAllEngines;

  /// Filter label for all extension languages
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get extensionsAllLanguages;

  /// Segment label for installed extensions with count
  ///
  /// In en, this message translates to:
  /// **'Installed ({count})'**
  String extensionsInstalledCount(String count);

  /// Segment label for available extensions with count
  ///
  /// In en, this message translates to:
  /// **'Get Extensions ({count})'**
  String extensionsGetExtensionsCount(String count);

  /// Tooltip for addons button on extensions screen
  ///
  /// In en, this message translates to:
  /// **'Addons (TorrServer)'**
  String get extensionsAddonsTooltip;

  /// Tooltip for testing extensions
  ///
  /// In en, this message translates to:
  /// **'Test Extensions'**
  String get extensionsTestTooltip;

  /// Tooltip for extension guide
  ///
  /// In en, this message translates to:
  /// **'Extension Guide'**
  String get extensionsGuideTooltip;

  /// Search hint for extensions
  ///
  /// In en, this message translates to:
  /// **'Search extensions...'**
  String get extensionsSearchHint;

  /// FAB label to manage engines
  ///
  /// In en, this message translates to:
  /// **'Manage Engines'**
  String get extensionsManageEngines;

  /// FAB label to manage repos
  ///
  /// In en, this message translates to:
  /// **'Manage Repos'**
  String get extensionsManageRepos;

  /// Bottom sheet title for managing extension engines
  ///
  /// In en, this message translates to:
  /// **'Manage Extension Engines'**
  String get extensionsManageEnginesTitle;

  /// Description inside manage extension engines sheet
  ///
  /// In en, this message translates to:
  /// **'Enable or disable external extension runtime engines. Enabled engines will appear in your catalogs and discovery feeds alongside your native inbuilt sources.'**
  String get extensionsManageEnginesDesc;

  /// Subtitle for Mangayomi engine
  ///
  /// In en, this message translates to:
  /// **'External runtime engine for Anime & Manga extensions'**
  String get extensionsEngineMangayomiDesc;

  /// Subtitle for Tachiyomi / Aniyomi engine
  ///
  /// In en, this message translates to:
  /// **'External runtime engine for Manga & Anime extensions'**
  String get extensionsEngineAniyomiDesc;

  /// Subtitle for CloudStream engine
  ///
  /// In en, this message translates to:
  /// **'External runtime engine for Video streaming extensions'**
  String get extensionsEngineCloudStreamDesc;

  /// Subtitle for Kotatsu engine
  ///
  /// In en, this message translates to:
  /// **'External runtime engine for Manga reading extensions'**
  String get extensionsEngineKotatsuDesc;

  /// Subtitle for Sora engine
  ///
  /// In en, this message translates to:
  /// **'External runtime engine for Novel & Anime extensions'**
  String get extensionsEngineSoraDesc;

  /// Introductory text on troubleshoot screen
  ///
  /// In en, this message translates to:
  /// **'Use these options if you encounter broken playback, frozen scrapers, desynced tracking, or corrupted settings.'**
  String get troubleshootIntro;

  /// Section title for storage & cache in troubleshoot
  ///
  /// In en, this message translates to:
  /// **'Storage & Cache'**
  String get troubleshootStorageCacheSection;

  /// Tile title to clean incomplete downloads
  ///
  /// In en, this message translates to:
  /// **'Clean Incomplete Downloads'**
  String get troubleshootCleanIncompleteDownloads;

  /// Tile subtitle for cleaning incomplete downloads
  ///
  /// In en, this message translates to:
  /// **'Review and purge {count} unfinished tasks & orphaned temp files'**
  String troubleshootCleanIncompleteDownloadsSubtitle(String count);

  /// Snackbar when no unfinished downloads found
  ///
  /// In en, this message translates to:
  /// **'No unfinished downloads or orphaned temp files found.'**
  String get troubleshootNoUnfinishedDownloads;

  /// Sheet title to review unfinished downloads
  ///
  /// In en, this message translates to:
  /// **'Review Unfinished Downloads'**
  String get troubleshootReviewUnfinishedTitle;

  /// Sheet description for reviewing unfinished downloads
  ///
  /// In en, this message translates to:
  /// **'Select unfinished queue tasks or incomplete temporary folders to permanently remove.'**
  String get troubleshootReviewUnfinishedDesc;

  /// Button label to clean up selected items
  ///
  /// In en, this message translates to:
  /// **'Clean Up ({count})'**
  String troubleshootCleanUpBtn(String count);

  /// Snackbar after cleaning up items
  ///
  /// In en, this message translates to:
  /// **'Cleaned up {count} item(s).'**
  String troubleshootCleanedUpSnack(String count);

  /// Tile title to clear image and poster cache
  ///
  /// In en, this message translates to:
  /// **'Clear Image & Poster Cache'**
  String get troubleshootClearImageCache;

  /// Tile subtitle to clear image and poster cache
  ///
  /// In en, this message translates to:
  /// **'Purge loaded cover art thumbnails and temp files from memory & disk'**
  String get troubleshootClearImageCacheSubtitle;

  /// Snackbar when image cache is purged
  ///
  /// In en, this message translates to:
  /// **'Image & poster cache purged from memory and disk.'**
  String get troubleshootImageCachePurged;

  /// Tile title to flush scraper cache
  ///
  /// In en, this message translates to:
  /// **'Flush Scraper Cache'**
  String get troubleshootFlushScraperCache;

  /// Tile subtitle to flush scraper cache
  ///
  /// In en, this message translates to:
  /// **'Clear {count} temporary scraper responses and stream links'**
  String troubleshootFlushScraperCacheSubtitle(String count);

  /// Snackbar when scraper cache is flushed
  ///
  /// In en, this message translates to:
  /// **'Scraper cache flushed.'**
  String get troubleshootScraperCacheFlushed;

  /// Section title for matching & scrapers
  ///
  /// In en, this message translates to:
  /// **'Matching & Scrapers'**
  String get troubleshootMatchingScrapersSection;

  /// Tile title to clear all media mappings
  ///
  /// In en, this message translates to:
  /// **'Clear All Media Mappings'**
  String get troubleshootClearMediaMappings;

  /// Tile subtitle to clear media mappings
  ///
  /// In en, this message translates to:
  /// **'Reset {count} preferred sources and manual matches'**
  String troubleshootClearMediaMappingsSubtitle(String count);

  /// Footnote under clear media mappings
  ///
  /// In en, this message translates to:
  /// **'Fixes \"Episodes Not Found\" after extension updates. Forces automatic re-matching on your next visit.'**
  String get troubleshootClearMediaMappingsNote;

  /// Dialog title to clear media mappings
  ///
  /// In en, this message translates to:
  /// **'Clear Media Mappings?'**
  String get troubleshootClearMediaMappingsDialogTitle;

  /// Dialog body to clear media mappings
  ///
  /// In en, this message translates to:
  /// **'This will clear {count} saved preferred sources and manual matches.'**
  String troubleshootClearMediaMappingsDialogBody(String count);

  /// Reassurance text that library, history, tracking are unaffected
  ///
  /// In en, this message translates to:
  /// **'Your library bookmarks, watch history, and tracking progression will not be affected.'**
  String get troubleshootLibraryNotAffected;

  /// Snackbar when media mappings are cleared
  ///
  /// In en, this message translates to:
  /// **'Media mappings cleared.'**
  String get troubleshootMappingsCleared;

  /// Section title for extensions & repositories
  ///
  /// In en, this message translates to:
  /// **'Extensions & Repositories'**
  String get troubleshootExtensionsReposSection;

  /// Tile title to clear all extension repos
  ///
  /// In en, this message translates to:
  /// **'Clear All Extension Repositories'**
  String get troubleshootClearAllReposTitle;

  /// Tile subtitle to clear all extension repos
  ///
  /// In en, this message translates to:
  /// **'Wipe all repository URLs across Aniyomi, Mangayomi, CloudStream, Kotatsu, and Sora'**
  String get troubleshootClearAllReposSubtitle;

  /// Dialog title to clear all repos
  ///
  /// In en, this message translates to:
  /// **'Clear All Repositories?'**
  String get troubleshootClearAllReposDialogTitle;

  /// Dialog body to clear all repos
  ///
  /// In en, this message translates to:
  /// **'This will remove all added extension repository URLs across Aniyomi, Mangayomi, CloudStream, Kotatsu, and Sora.\n\nInstalled extensions will remain until uninstalled.'**
  String get troubleshootClearAllReposDialogBody;

  /// Button label Clear All
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get troubleshootClearAllBtn;

  /// Snackbar when all extension repos are cleared
  ///
  /// In en, this message translates to:
  /// **'All extension repositories cleared.'**
  String get troubleshootAllReposCleared;

  /// Tile title to uninstall all extensions
  ///
  /// In en, this message translates to:
  /// **'Uninstall All Extensions'**
  String get troubleshootUninstallAllExtTitle;

  /// Tile subtitle to uninstall all extensions
  ///
  /// In en, this message translates to:
  /// **'Uninstall all extension plugins across all engines to fix corrupted builds'**
  String get troubleshootUninstallAllExtSubtitle;

  /// Dialog title to uninstall all extensions
  ///
  /// In en, this message translates to:
  /// **'Uninstall All Extensions?'**
  String get troubleshootUninstallAllExtDialogTitle;

  /// Dialog body to uninstall all extensions
  ///
  /// In en, this message translates to:
  /// **'This will remove all installed extension plugins across all engines.\n\nFixes crashes or broken sources caused by outdated/corrupted extension installs.'**
  String get troubleshootUninstallAllExtDialogBody;

  /// Button label Uninstall All
  ///
  /// In en, this message translates to:
  /// **'Uninstall All'**
  String get troubleshootUninstallAllBtn;

  /// Snackbar when all extensions are uninstalled
  ///
  /// In en, this message translates to:
  /// **'All installed extensions uninstalled.'**
  String get troubleshootAllExtUninstalled;

  /// Tile title to reset extension cache & preferences
  ///
  /// In en, this message translates to:
  /// **'Reset Extension Cache & Preferences'**
  String get troubleshootResetExtCacheTitle;

  /// Tile subtitle to reset extension cache & preferences
  ///
  /// In en, this message translates to:
  /// **'Clear custom source preferences, cached metadata, and refresh engines'**
  String get troubleshootResetExtCacheSubtitle;

  /// Dialog title to reset extension cache & preferences
  ///
  /// In en, this message translates to:
  /// **'Reset Extension Cache & Preferences?'**
  String get troubleshootResetExtCacheDialogTitle;

  /// Dialog body to reset extension cache & preferences
  ///
  /// In en, this message translates to:
  /// **'This will reset extension-specific settings, source preferences, and cached metadata, then reload active extension managers.'**
  String get troubleshootResetExtCacheDialogBody;

  /// Snackbar when extension cache & preferences are reset
  ///
  /// In en, this message translates to:
  /// **'Extension cache and preferences reset.'**
  String get troubleshootExtCacheResetSnack;

  /// Section title for sync & tracking
  ///
  /// In en, this message translates to:
  /// **'Sync & Tracking'**
  String get troubleshootSyncTrackingSection;

  /// Tile title to reset tracker bridges
  ///
  /// In en, this message translates to:
  /// **'Reset Tracker Bridges'**
  String get troubleshootResetTrackerBridges;

  /// Tile subtitle to reset tracker bridges
  ///
  /// In en, this message translates to:
  /// **'Clear {count} cached AniList to MAL ID pairings'**
  String troubleshootResetTrackerBridgesSubtitle(String count);

  /// Dialog title to clear tracker bridges
  ///
  /// In en, this message translates to:
  /// **'Clear Tracker Bridges?'**
  String get troubleshootClearTrackerBridgesDialogTitle;

  /// Snackbar when tracker bridges are cleared
  ///
  /// In en, this message translates to:
  /// **'Tracker bridges cleared.'**
  String get troubleshootTrackerBridgesCleared;

  /// Section title for authentication & accounts
  ///
  /// In en, this message translates to:
  /// **'Authentication & Accounts'**
  String get troubleshootAuthAccountsSection;

  /// Tile title to reset authentication data
  ///
  /// In en, this message translates to:
  /// **'Reset Authentication Data'**
  String get troubleshootResetAuthTitle;

  /// Tile subtitle to reset authentication data
  ///
  /// In en, this message translates to:
  /// **'Log out and erase all saved credentials (AniList, MAL, Kitsu, SIMKL, Discord, Commentum)'**
  String get troubleshootResetAuthSubtitle;

  /// Dialog title to reset auth data
  ///
  /// In en, this message translates to:
  /// **'Reset Authentication Data?'**
  String get troubleshootResetAuthDialogTitle;

  /// Dialog lead text for resetting auth data
  ///
  /// In en, this message translates to:
  /// **'This will sign out of all linked accounts and erase saved tokens:'**
  String get troubleshootResetAuthDialogLead;

  /// Bullet list of services signed out
  ///
  /// In en, this message translates to:
  /// **'• Tracker accounts (AniList, MyAnimeList, Kitsu, SIMKL)\n• Discord Rich Presence integration\n• Commentum discussions session'**
  String get troubleshootResetAuthDialogList;

  /// Note that local bookmarks, history, and downloads are safe
  ///
  /// In en, this message translates to:
  /// **'Your local bookmarks, watch history, and downloads will NOT be affected.'**
  String get troubleshootLocalDataSafeNote;

  /// Button label Reset Auth
  ///
  /// In en, this message translates to:
  /// **'Reset Auth'**
  String get troubleshootResetAuthBtn;

  /// Snackbar when auth tokens are cleared
  ///
  /// In en, this message translates to:
  /// **'All authentication tokens cleared and accounts signed out.'**
  String get troubleshootAuthClearedSnack;

  /// Section title for data management & reset
  ///
  /// In en, this message translates to:
  /// **'Data Management & Reset'**
  String get troubleshootDataMgmtSection;

  /// Tile & sheet title for selective data clear
  ///
  /// In en, this message translates to:
  /// **'Clear App Data (Selective)'**
  String get troubleshootClearDataSelectiveTitle;

  /// Tile subtitle for selective data clear
  ///
  /// In en, this message translates to:
  /// **'Selectively wipe history, bookmarks, caches, mappings, or perform a full wipe'**
  String get troubleshootClearDataSelectiveSubtitle;

  /// Label in selective clear sheet
  ///
  /// In en, this message translates to:
  /// **'Select data categories to purge:'**
  String get troubleshootSelectCategoriesToPurge;

  /// Dialog title to confirm selective data wipe
  ///
  /// In en, this message translates to:
  /// **'Confirm Data Wipe?'**
  String get troubleshootConfirmDataWipeTitle;

  /// Dialog body to confirm selective data wipe
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the {count} selected categories. This action cannot be undone.'**
  String troubleshootConfirmDataWipeBody(String count);

  /// Button label Wipe Selected
  ///
  /// In en, this message translates to:
  /// **'Wipe Selected'**
  String get troubleshootWipeSelectedBtn;

  /// Button label Wipe Selected with count
  ///
  /// In en, this message translates to:
  /// **'Wipe Selected ({count})'**
  String troubleshootWipeSelectedCountBtn(String count);

  /// Snackbar after purging selected categories
  ///
  /// In en, this message translates to:
  /// **'Purged {count} selected data categories.'**
  String troubleshootPurgedCategoriesSnack(String count);

  /// Tile title to reset app settings to default
  ///
  /// In en, this message translates to:
  /// **'Reset App Settings to Default'**
  String get troubleshootResetAppSettingsTitle;

  /// Tile subtitle to reset app settings
  ///
  /// In en, this message translates to:
  /// **'Restore all player, UI, and extension preferences without affecting saved data'**
  String get troubleshootResetAppSettingsSubtitle;

  /// Dialog title to reset app settings
  ///
  /// In en, this message translates to:
  /// **'Reset App Settings?'**
  String get troubleshootResetAppSettingsDialogTitle;

  /// Dialog body to reset app settings
  ///
  /// In en, this message translates to:
  /// **'This will revert all player, UI theme, extension, and content settings back to factory defaults.\n\nYour library bookmarks, history, and downloads will remain intact.'**
  String get troubleshootResetAppSettingsDialogBody;

  /// Button label Reset Settings
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get troubleshootResetSettingsBtn;

  /// Snackbar when app settings are restored
  ///
  /// In en, this message translates to:
  /// **'App settings restored to defaults.'**
  String get troubleshootSettingsRestoredSnack;

  /// Category title for watch & read history
  ///
  /// In en, this message translates to:
  /// **'Watch & Read History'**
  String get troubleshootCatHistory;

  /// Category subtitle for history count
  ///
  /// In en, this message translates to:
  /// **'{count} history entries'**
  String troubleshootCatHistorySub(String count);

  /// Category title for library & bookmarks
  ///
  /// In en, this message translates to:
  /// **'Library & Bookmarks'**
  String get troubleshootCatLibrary;

  /// Category subtitle for library count
  ///
  /// In en, this message translates to:
  /// **'{count} saved titles in your library'**
  String troubleshootCatLibrarySub(String count);

  /// Category title for scraper & network cache
  ///
  /// In en, this message translates to:
  /// **'Scraper & Network Cache'**
  String get troubleshootCatCache;

  /// Category subtitle for cache count
  ///
  /// In en, this message translates to:
  /// **'{count} cached API responses and stream links'**
  String troubleshootCatCacheSub(String count);

  /// Category title for media & source mappings
  ///
  /// In en, this message translates to:
  /// **'Media & Source Mappings'**
  String get troubleshootCatMappings;

  /// Category subtitle for mappings count
  ///
  /// In en, this message translates to:
  /// **'{count} preferred sources and manual matches'**
  String troubleshootCatMappingsSub(String count);

  /// Category title for tracker bridges
  ///
  /// In en, this message translates to:
  /// **'Tracker Bridges'**
  String get troubleshootCatBridges;

  /// Category subtitle for tracker bridges count
  ///
  /// In en, this message translates to:
  /// **'{count} AniList to MAL ID mapping links'**
  String troubleshootCatBridgesSub(String count);

  /// Category title for incomplete downloads & temp files
  ///
  /// In en, this message translates to:
  /// **'Incomplete Downloads & Temp Files'**
  String get troubleshootCatDownloads;

  /// Category subtitle for incomplete downloads count
  ///
  /// In en, this message translates to:
  /// **'{count} pending download tasks and temp files'**
  String troubleshootCatDownloadsSub(String count);

  /// Category subtitle for saved auth tokens count
  ///
  /// In en, this message translates to:
  /// **'{count} saved tokens (AniList, MAL, Kitsu, Discord)'**
  String troubleshootCatAuthSub(String count);

  /// Category title for app preferences & settings
  ///
  /// In en, this message translates to:
  /// **'App Preferences & Settings'**
  String get troubleshootCatSettings;

  /// Category subtitle for app preferences & settings
  ///
  /// In en, this message translates to:
  /// **'Reset all player, UI, and extension settings to defaults'**
  String get troubleshootCatSettingsSub;

  /// Sheet title for global UI customization
  ///
  /// In en, this message translates to:
  /// **'Global UI Customization'**
  String get appearanceGlobalUiTitle;

  /// Slider title for border roundness
  ///
  /// In en, this message translates to:
  /// **'Border Roundness'**
  String get appearanceBorderRoundness;

  /// Slider subtitle for border roundness
  ///
  /// In en, this message translates to:
  /// **'Corner roundness across the app'**
  String get appearanceBorderRoundnessSubtitle;

  /// Slider title for font scale
  ///
  /// In en, this message translates to:
  /// **'Font Scale'**
  String get appearanceFontScale;

  /// Slider subtitle for font scale
  ///
  /// In en, this message translates to:
  /// **'Scale text size globally'**
  String get appearanceFontScaleSubtitle;

  /// Slider title for widget scale
  ///
  /// In en, this message translates to:
  /// **'Widget Scale'**
  String get appearanceWidgetScale;

  /// Slider subtitle for widget scale
  ///
  /// In en, this message translates to:
  /// **'Scale media cards & navigation bar'**
  String get appearanceWidgetScaleSubtitle;

  /// Preview primary text
  ///
  /// In en, this message translates to:
  /// **'Primary text'**
  String get appearancePrimaryText;

  /// Preview secondary text
  ///
  /// In en, this message translates to:
  /// **'Secondary text'**
  String get appearanceSecondaryText;

  /// Default toggles title in picker sheet shell
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get pickerDisplayOptions;

  /// Options title for card style picker
  ///
  /// In en, this message translates to:
  /// **'Card Style Preset'**
  String get pickerCardStylePreset;

  /// Options title for continue watching style picker
  ///
  /// In en, this message translates to:
  /// **'Continue Watching Style Preset'**
  String get pickerContinueWatchingPreset;

  /// Options title for continue reading style picker
  ///
  /// In en, this message translates to:
  /// **'Continue Reading Style Preset'**
  String get pickerContinueReadingPreset;

  /// FilterChip label for ratings
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get pickerRatingsChip;

  /// FilterChip label for release year
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get pickerReleaseYearChip;

  /// FilterChip label for wide mode
  ///
  /// In en, this message translates to:
  /// **'Wide Mode'**
  String get pickerWideModeChip;

  /// FilterChip label for portrait mode
  ///
  /// In en, this message translates to:
  /// **'Portrait Mode'**
  String get pickerPortraitModeChip;

  /// Description for classic card style
  ///
  /// In en, this message translates to:
  /// **'Classic poster layout with metadata overlay'**
  String get cardStyleClassicDesc;

  /// Description for minimal card style
  ///
  /// In en, this message translates to:
  /// **'Clean border-free poster card'**
  String get cardStyleMinimalDesc;

  /// Description for expressive card style
  ///
  /// In en, this message translates to:
  /// **'Spacious container with bold badges'**
  String get cardStyleExpressiveDesc;

  /// Description for material card style
  ///
  /// In en, this message translates to:
  /// **'Rounded Material card styling'**
  String get cardStyleMaterialDesc;

  /// Description for cinematic card style
  ///
  /// In en, this message translates to:
  /// **'Full-bleed cinematic landscape view'**
  String get cardStyleCinematicDesc;

  /// Description for neon card style
  ///
  /// In en, this message translates to:
  /// **'Glowing vibrant accent borders'**
  String get cardStyleNeonDesc;

  /// Description for compact card style
  ///
  /// In en, this message translates to:
  /// **'Dense compact layout for high density'**
  String get cardStyleCompactDesc;

  /// Description for editorial card style
  ///
  /// In en, this message translates to:
  /// **'High-whitespace magazine design'**
  String get cardStyleEditorialDesc;

  /// Description for wide banner card style
  ///
  /// In en, this message translates to:
  /// **'Wide horizontal banner card'**
  String get cardStyleWideBannerDesc;

  /// Sheet title for episode view mode
  ///
  /// In en, this message translates to:
  /// **'Episode View Mode'**
  String get episodeModeTitle;

  /// Options title for episode view mode
  ///
  /// In en, this message translates to:
  /// **'Episode View Mode Preset'**
  String get episodeModePreset;

  /// Description for classic episode mode
  ///
  /// In en, this message translates to:
  /// **'Detailed list with episode art and title'**
  String get episodeModeClassicDesc;

  /// Description for grid episode mode
  ///
  /// In en, this message translates to:
  /// **'Thumbnail grid with episode numbers'**
  String get episodeModeGridDesc;

  /// Description for box episode mode
  ///
  /// In en, this message translates to:
  /// **'Compact numbered boxes — great for long anime'**
  String get episodeModeBoxDesc;

  /// Description for compact episode mode
  ///
  /// In en, this message translates to:
  /// **'Clean text rows without thumbnails for fast browsing'**
  String get episodeModeCompactDesc;

  /// Description for cover episode mode
  ///
  /// In en, this message translates to:
  /// **'Wide landscape cards with thumbnail preview and details'**
  String get episodeModeCoverDesc;

  /// Sheet title for home header style
  ///
  /// In en, this message translates to:
  /// **'Home Header Style'**
  String get headerStyleTitle;

  /// Options title for home header style
  ///
  /// In en, this message translates to:
  /// **'Header Layout Preset'**
  String get headerStylePreset;

  /// Description for classic header style
  ///
  /// In en, this message translates to:
  /// **'Balanced avatar and greeting'**
  String get headerStyleClassicDesc;

  /// Description for minimal header style
  ///
  /// In en, this message translates to:
  /// **'Compact single-line row'**
  String get headerStyleMinimalDesc;

  /// Description for material header style
  ///
  /// In en, this message translates to:
  /// **'Segmented pill layout'**
  String get headerStyleMaterialDesc;

  /// Description for prominent header style
  ///
  /// In en, this message translates to:
  /// **'Expressive hero layout'**
  String get headerStyleProminentDesc;

  /// Description for docked header style
  ///
  /// In en, this message translates to:
  /// **'Seamless side-by-side tv layout'**
  String get headerStyleDockedDesc;

  /// Options title for nav bar style
  ///
  /// In en, this message translates to:
  /// **'Navigation Bar Preset'**
  String get navBarStylePreset;

  /// Description for classic nav bar
  ///
  /// In en, this message translates to:
  /// **'Floating container with modern backdrop blur'**
  String get navBarClassicDesc;

  /// Description for minimal nav bar
  ///
  /// In en, this message translates to:
  /// **'Sleek, transparent floating glass dock style'**
  String get navBarMinimalDesc;

  /// Description for frosted nav bar
  ///
  /// In en, this message translates to:
  /// **'Super-translucent frosted glassmorphism layout'**
  String get navBarFrostedDesc;

  /// Description for material nav bar
  ///
  /// In en, this message translates to:
  /// **'Material You rounded capsules with navigation indicators'**
  String get navBarMaterialDesc;

  /// Description for docked nav bar
  ///
  /// In en, this message translates to:
  /// **'Solid edge-to-edge layout connected to screen bottom'**
  String get navBarDockedDesc;

  /// Sheet title for preset gallery
  ///
  /// In en, this message translates to:
  /// **'Preset Gallery'**
  String get presetsGalleryTitle;

  /// Chip label for curated presets count
  ///
  /// In en, this message translates to:
  /// **'Curated ({count})'**
  String presetsCuratedCount(String count);

  /// Chip label for custom presets count
  ///
  /// In en, this message translates to:
  /// **'Custom ({count})'**
  String presetsCustomCount(String count);

  /// Header for built-in themes
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN THEMES'**
  String get presetsBuiltInHeader;

  /// Header for user custom themes
  ///
  /// In en, this message translates to:
  /// **'YOUR CUSTOM THEMES'**
  String get presetsCustomHeader;

  /// Snackbar when a preset is loaded
  ///
  /// In en, this message translates to:
  /// **'Loaded preset: {name}'**
  String presetsLoadedSnack(String name);

  /// Empty state title for custom presets
  ///
  /// In en, this message translates to:
  /// **'No custom presets yet'**
  String get presetsNoCustomTitle;

  /// Empty state subtitle for custom presets
  ///
  /// In en, this message translates to:
  /// **'Use \"Create Theme\" above or import a .json theme from the community.'**
  String get presetsNoCustomSubtitle;

  /// Button label to snapshot current theme
  ///
  /// In en, this message translates to:
  /// **'Snapshot Current'**
  String get presetsSnapshotCurrent;

  /// Button label to import JSON preset
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get presetsImportJson;

  /// Button label to export preset
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get presetsExport;

  /// Sheet title to export preset JSON
  ///
  /// In en, this message translates to:
  /// **'Export Preset JSON'**
  String get presetsExportPresetTitle;

  /// Sheet title to export current theme
  ///
  /// In en, this message translates to:
  /// **'Export Current Theme'**
  String get presetsExportCurrentTitle;

  /// Prompt text when exporting a named preset
  ///
  /// In en, this message translates to:
  /// **'Customize the metadata before exporting \"{name}\" to clipboard:'**
  String presetsExportPresetPrompt(String name);

  /// Prompt text when exporting current theme
  ///
  /// In en, this message translates to:
  /// **'Customize the metadata before exporting your current theme settings to clipboard:'**
  String get presetsExportCurrentPrompt;

  /// TextField label for preset name
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get presetsPresetName;

  /// TextField label for author/creator
  ///
  /// In en, this message translates to:
  /// **'Author / Creator'**
  String get presetsAuthorCreator;

  /// TextField label for preset description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get presetsDescription;

  /// Button label to copy JSON
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get presetsCopyJson;

  /// Snackbar when preset JSON is copied
  ///
  /// In en, this message translates to:
  /// **'Copied \"{name}\" JSON by {author} to clipboard!'**
  String presetsCopiedSnack(String author, String name);

  /// Sheet title to import theme JSON
  ///
  /// In en, this message translates to:
  /// **'Import Theme (.json)'**
  String get presetsImportTitle;

  /// Prompt to paste theme JSON
  ///
  /// In en, this message translates to:
  /// **'Paste a ShonenX Theme JSON code below:'**
  String get presetsPasteBelow;

  /// Button label to paste from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste Clipboard'**
  String get presetsPasteClipboard;

  /// Button label to save imported preset without applying
  ///
  /// In en, this message translates to:
  /// **'Save Only'**
  String get presetsSaveOnly;

  /// Button label to install and apply imported preset
  ///
  /// In en, this message translates to:
  /// **'Install & Apply'**
  String get presetsInstallApply;

  /// Snackbar when preset is saved without applying
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\" to Custom Themes (not applied).'**
  String presetsSavedNotApplied(String name);

  /// Snackbar when preset is installed and applied
  ///
  /// In en, this message translates to:
  /// **'Successfully installed & applied \"{name}\"!'**
  String presetsInstalledApplied(String name);

  /// Snackbar when imported JSON is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format: {error}'**
  String presetsInvalidJson(String error);

  /// Sheet title to snapshot current theme
  ///
  /// In en, this message translates to:
  /// **'Snapshot Current Theme'**
  String get presetsSnapshotTitle;

  /// Button label to save snapshot
  ///
  /// In en, this message translates to:
  /// **'Save Snapshot'**
  String get presetsSaveSnapshot;

  /// Snackbar when snapshot is saved
  ///
  /// In en, this message translates to:
  /// **'Saved \"{name}\" to your presets!'**
  String presetsSavedSnapshotSnack(String name);

  /// Tooltip for exporting/sharing preset
  ///
  /// In en, this message translates to:
  /// **'Export / Share JSON'**
  String get presetsExportShareTooltip;

  /// Tooltip for deleting custom preset
  ///
  /// In en, this message translates to:
  /// **'Delete Preset'**
  String get presetsDeleteTooltip;

  /// ExpansionTile title for advanced subtitle settings
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get subtitleAdvancedSettings;

  /// Switch title for custom engine overlay
  ///
  /// In en, this message translates to:
  /// **'Custom Engine Overlay'**
  String get subtitleCustomEngineOverlay;

  /// Warning when native subtitles are active
  ///
  /// In en, this message translates to:
  /// **'Native subtitles active. Some appearance settings may be ignored.'**
  String get subtitleNativeActiveWarning;

  /// Dropdown title for subtitle font family
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get subtitleFontFamily;

  /// Slider title for subtitle size scale
  ///
  /// In en, this message translates to:
  /// **'Size Scale'**
  String get subtitleSizeScale;

  /// Tile title for subtitle font color
  ///
  /// In en, this message translates to:
  /// **'Font Color'**
  String get subtitleFontColor;

  /// Switch title for bold subtitle text
  ///
  /// In en, this message translates to:
  /// **'Bold Text'**
  String get subtitleBoldText;

  /// Slider title for subtitle line height
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get subtitleLineHeight;

  /// Tile title for subtitle outline color
  ///
  /// In en, this message translates to:
  /// **'Outline Color'**
  String get subtitleOutlineColor;

  /// Slider title for subtitle outline size
  ///
  /// In en, this message translates to:
  /// **'Outline Size'**
  String get subtitleOutlineSize;

  /// Tile title for subtitle shadow color
  ///
  /// In en, this message translates to:
  /// **'Shadow Color'**
  String get subtitleShadowColor;

  /// Slider title for subtitle shadow blur
  ///
  /// In en, this message translates to:
  /// **'Shadow Blur'**
  String get subtitleShadowBlur;

  /// Slider title for subtitle bottom padding
  ///
  /// In en, this message translates to:
  /// **'Bottom Padding'**
  String get subtitleBottomPadding;

  /// Slider title for subtitle background padding
  ///
  /// In en, this message translates to:
  /// **'Background Padding'**
  String get subtitleBgPadding;

  /// Slider title for subtitle letter spacing
  ///
  /// In en, this message translates to:
  /// **'Letter Spacing'**
  String get subtitleLetterSpacing;

  /// Slider title for subtitle word spacing
  ///
  /// In en, this message translates to:
  /// **'Word Spacing'**
  String get subtitleWordSpacing;

  /// TextField label for hex color code
  ///
  /// In en, this message translates to:
  /// **'Hex Code (AARRGGBB)'**
  String get subtitleHexCodeLabel;

  /// Switch title to enable subtitle translation
  ///
  /// In en, this message translates to:
  /// **'Enable Translation'**
  String get subtitleTransEnable;

  /// Switch title for auto-translate
  ///
  /// In en, this message translates to:
  /// **'Auto-Translate'**
  String get subtitleTransAuto;

  /// Switch subtitle for auto-translate
  ///
  /// In en, this message translates to:
  /// **'Translate when preferred subtitle language is missing'**
  String get subtitleTransAutoSubtitle;

  /// Dropdown title for translation strategy
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get subtitleTransStrategy;

  /// Dropdown item for bulk translation
  ///
  /// In en, this message translates to:
  /// **'Bulk (Pre-load full episode)'**
  String get subtitleTransStrategyBulk;

  /// Dropdown item for on-demand translation
  ///
  /// In en, this message translates to:
  /// **'On-Demand (Live chunks)'**
  String get subtitleTransStrategyOnDemand;

  /// Section title for translation provider priority
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get subtitleTransProviderPriority;

  /// Section title for API keys
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get subtitleTransApiKeys;

  /// Subtitle when provider is configured
  ///
  /// In en, this message translates to:
  /// **'Configured ({detail})'**
  String subtitleTransConfigured(String detail);

  /// Subtitle to set API key
  ///
  /// In en, this message translates to:
  /// **'Set API Key'**
  String get subtitleTransSetApiKey;

  /// Subtitle to set DeepL auth key
  ///
  /// In en, this message translates to:
  /// **'Set Auth Key'**
  String get subtitleTransSetAuthKey;

  /// Subtitle to set OpenAI API key and URL
  ///
  /// In en, this message translates to:
  /// **'Set API Key & URL'**
  String get subtitleTransSetApiKeyUrl;

  /// Label while calculating cache size
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get subtitleTransCalculating;

  /// Subtitle for free Google translate provider
  ///
  /// In en, this message translates to:
  /// **'Free (No key needed)'**
  String get subtitleTransFreeNoKey;

  /// Subtitle when API key is missing
  ///
  /// In en, this message translates to:
  /// **'Key missing'**
  String get subtitleTransKeyMissing;

  /// TextField label for API Key
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get subtitleTransApiKeyLabel;

  /// TextField label for AI model
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get subtitleTransModelLabel;

  /// TextField label for DeepL Auth Key
  ///
  /// In en, this message translates to:
  /// **'Auth Key'**
  String get subtitleTransAuthKeyLabel;

  /// Switch title for DeepL Pro API
  ///
  /// In en, this message translates to:
  /// **'Use DeepL Pro API'**
  String get subtitleTransUseDeepLPro;

  /// TextField label for OpenAI Base URL
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get subtitleTransBaseUrlLabel;

  /// Dialog body to confirm clearing subtitle translation cache
  ///
  /// In en, this message translates to:
  /// **'Delete all saved offline translations?'**
  String get subtitleTransDeleteAllConfirm;

  /// Section title for surface styling
  ///
  /// In en, this message translates to:
  /// **'Surface Styling'**
  String get themeEffectsSurfaceStyling;

  /// Slider title for blend level
  ///
  /// In en, this message translates to:
  /// **'Blend Level'**
  String get themeEffectsBlendLevel;

  /// Slider subtitle for blend level
  ///
  /// In en, this message translates to:
  /// **'Color infusion intensity'**
  String get themeEffectsBlendLevelSubtitle;

  /// Switch title for gradient surfaces
  ///
  /// In en, this message translates to:
  /// **'Gradient Surfaces'**
  String get themeEffectsGradientSurfaces;

  /// Subtitle when effect is disabled with Pure Black
  ///
  /// In en, this message translates to:
  /// **'Disabled with Pure Black'**
  String get themeEffectsDisabledWithPureBlack;

  /// Switch subtitle for gradient surfaces
  ///
  /// In en, this message translates to:
  /// **'Subtle gradients instead of flat fills'**
  String get themeEffectsGradientSurfacesSubtitle;

  /// Dropdown title for gradient shape
  ///
  /// In en, this message translates to:
  /// **'Gradient Shape'**
  String get themeEffectsGradientShape;

  /// Dropdown title for gradient angle
  ///
  /// In en, this message translates to:
  /// **'Gradient Angle'**
  String get themeEffectsGradientAngle;

  /// Dropdown title for gradient palette
  ///
  /// In en, this message translates to:
  /// **'Gradient Palette'**
  String get themeEffectsGradientPalette;

  /// Slider title for gradient intensity
  ///
  /// In en, this message translates to:
  /// **'Gradient Intensity'**
  String get themeEffectsGradientIntensity;

  /// Slider subtitle for gradient intensity
  ///
  /// In en, this message translates to:
  /// **'Color vibrancy over background'**
  String get themeEffectsGradientIntensitySubtitle;

  /// Section title for texture
  ///
  /// In en, this message translates to:
  /// **'Texture'**
  String get themeEffectsTextureSection;

  /// Switch title for noise overlay
  ///
  /// In en, this message translates to:
  /// **'Noise Overlay'**
  String get themeEffectsNoiseOverlay;

  /// Switch subtitle for noise overlay
  ///
  /// In en, this message translates to:
  /// **'Overlay a subtle textured grain grid'**
  String get themeEffectsNoiseOverlaySubtitle;

  /// Slider title for noise intensity
  ///
  /// In en, this message translates to:
  /// **'Noise Intensity'**
  String get themeEffectsNoiseIntensity;

  /// Slider subtitle for noise intensity
  ///
  /// In en, this message translates to:
  /// **'Textured grain strength'**
  String get themeEffectsNoiseIntensitySubtitle;

  /// Tile title for custom wallpaper
  ///
  /// In en, this message translates to:
  /// **'Custom Wallpaper'**
  String get themeWallpaperCustomTitle;

  /// Subtitle to change custom background image
  ///
  /// In en, this message translates to:
  /// **'Change custom background image'**
  String get themeWallpaperChangeSubtitle;

  /// Subtitle to select custom background image
  ///
  /// In en, this message translates to:
  /// **'Select a custom background image'**
  String get themeWallpaperSelectSubtitle;

  /// Tile title to customize wallpaper
  ///
  /// In en, this message translates to:
  /// **'Customize Wallpaper'**
  String get themeWallpaperCustomizeTitle;

  /// Tile subtitle to customize wallpaper
  ///
  /// In en, this message translates to:
  /// **'Adjust blur, opacity, saturation, and brightness'**
  String get themeWallpaperCustomizeSubtitle;

  /// Switch title to use wallpaper colors
  ///
  /// In en, this message translates to:
  /// **'Use Wallpaper Colors'**
  String get themeWallpaperUseColors;

  /// Switch subtitle to generate theme colors from wallpaper
  ///
  /// In en, this message translates to:
  /// **'Generate theme colors from the wallpaper'**
  String get themeWallpaperUseColorsSubtitle;

  /// Tile title to remove wallpaper
  ///
  /// In en, this message translates to:
  /// **'Remove Wallpaper'**
  String get themeWallpaperRemoveTitle;

  /// Tile subtitle to remove wallpaper
  ///
  /// In en, this message translates to:
  /// **'Clear custom background image'**
  String get themeWallpaperRemoveSubtitle;

  /// Button label to apply wallpaper
  ///
  /// In en, this message translates to:
  /// **'Apply Wallpaper'**
  String get themeWallpaperApplyBtn;

  /// Badge label showing count of themes
  ///
  /// In en, this message translates to:
  /// **'{count} Themes'**
  String themeCountThemes(String count);

  /// Badge label showing count of palettes
  ///
  /// In en, this message translates to:
  /// **'{count} Palettes'**
  String themeCountPalettes(String count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'pt',
    'yue',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'yue':
      return AppLocalizationsYue();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
