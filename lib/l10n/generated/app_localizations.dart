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
