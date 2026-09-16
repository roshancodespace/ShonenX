# Matchmaker

A critical challenge for multi-source clients is identity resolution. 

A user's AniList account identifies *Naruto* with ID `20`. However, a random web extension might identify *Naruto* as `/anime/naruto-shippuden-1080p`.

The [`matchmaker`](https://github.com/roshancodespace/shonenx/tree/main/lib/source_engine/matchmaker/) subsystem resolves this discrepancy automatically.

## Resolution Flow

1.  **Metadata Fetch:** The user taps a title on their home feed (driven by AniList metadata).
2.  **Query Generation:** The `Matchmaker` reads the normalized title and alternate aliases.
3.  **Source Execution:** The `Matchmaker` searches the actively selected source (e.g., an Aniyomi extension) using those strings.
4.  **Binding:** An internal similarity algorithm evaluates the returned results (checking string distance, release year, and format) to identify the exact match on the source website.
5.  **Persistence:** The relationship `(AniListID <-> SourceURL)` is cached locally. Future requests bypass the search phase entirely.

This ensures seamless tracking integration without forcing the user to manually select the correct result from the source every time.
