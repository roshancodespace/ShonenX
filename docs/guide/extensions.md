# Extensions Guide

ShonenX does not ship with pre-loaded media sources. Instead, it provides an extensible runtime bridge that allows users to add repositories from popular community formats.

Once a repository is installed, ShonenX can execute scrapers from **Mangayomi**, **Cloudstream**, and **Aniyomi** within the app.

---

## Supported Ecosystems

ShonenX currently supports extensions from:
- **Mangayomi:** Anime and Manga sources (Dart and JavaScript based).
- **Cloudstream:** Anime and multi-source video extractors.
- **Aniyomi / Tachiyomi:** Manga extensions with comprehensive catalog coverage.
- **Kotatsu & Sora:** Dedicated manga and anime formats.

---

## How to Add an Extension Repository

Adding a repository takes a few simple steps:

```
[Settings] ➔ [Extensions] ➔ [Manage Repos (+)] ➔ [Paste Repo URL] ➔ [Save]
```

1. In ShonenX, navigate to **Settings → Extensions**.
2. Tap the **Manage Repos** button (floating action button in the lower right).
3. Select your **Target Engine** (e.g., `Mangayomi`, `CloudStream`, or `Tachiyomi`).
4. Paste the repository URL into the text field.
5. Select the **Repository Type** (Anime or Manga).
6. Tap **Add Repository**.
7. Once loaded, browse and enable the individual extensions you wish to use.

---

## Troubleshooting Search & Match Results

If an enabled extension does not immediately return results for a specific title:

### 1. Title Variations (English vs. Romaji)
Tracker services (like AniList or MAL) may index a title in English (e.g. *Attack on Titan*), while a particular source lists it primarily in Japanese Romaji (e.g. *Shingeki no Kyojin*).
*   **Recommendation:** Try searching using both the Romanized Japanese title and the localized English title.

### 2. Punctuation and Season Formats
Certain sources index sequels as separate entries (e.g. *Season 2* vs *2nd Season* vs subtitle names).
*   **Recommendation:** Search using the root title if a specific season query does not yield immediate results.

### 3. Extension Repository Updates
Online sources periodically change web layouts or domain names.
*   **Recommendation:** Go to **Settings → Extensions**, tap your repository, and select **Check for Updates** to pull the latest source definitions.
