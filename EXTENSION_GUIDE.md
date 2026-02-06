# ShonenX Extension Development Guide

This guide explains how to create extensions for ShonenX using JavaScript. ShonenX extensions allow you to integrate anime sources directly into the application.

## Core Concepts

Extensions in ShonenX are JavaScript classes that extend `MProvider`. They implement specific methods to fetch content, parse HTML, and return data to the application.

### The `MProvider` Class

Your extension must extend this class. It provides:
- `this.source`: Information about the source (baseUrl, lang, etc.)
- `this.client`: A built-in HTTP client for making requests.
- `DomSelector`: Helper for parsing HTML (available globally).

## Structure

```javascript
class DefaultExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
    }

    // ... methods ...
}
```

## Methods to Implement

### 1. `getPopular(page)`
Fetches a list of popular anime.
- **Args**: `page` (number)
- **Returns**: Object `{ list: [Anime], hasNextPage: boolean }`

### 2. `getLatestUpdates(page)`
Fetches a list of recently updated anime.
- **Args**: `page` (number)
- **Returns**: Object `{ list: [Anime], hasNextPage: boolean }`

### 3. `search(query, page, filters)`
Searches for anime.
- **Args**: `query` (string), `page` (number), `filters` (List<Filter>)
- **Returns**: Object `{ list: [Anime], hasNextPage: boolean }`

### 4. `getDetail(url)`
Fetches detailed information about an anime.
- **Args**: `url` (string) - relative or absolute URL
- **Returns**: `AnimeDetail` object

### 5. `getSupportedServers(animeId, episodeId, episodeNumber)`
**[ShonenX Exclusive]** Fetches available servers for a specific episode.
- **Args**:
    - `animeId`: ID of the anime (from `getDetail` or source-specific)
    - `episodeId`: ID of the episode
    - `episodeNumber`: Number of the episode
- **Returns**: `List<ServerData>`

### 6. `getVideos(animeId, episodeId, serverId, category)`
**[ShonenX Exclusive]** Fetches video streams for a chosen server.
- **Args**:
    - `animeId`: ID of the anime
    - `episodeId`: ID of the episode
    - `serverId`: ID of the selected server
    - `category`: Category of the server (sub/dub/raw) - *optional usage depending on source*
- **Returns**: `List<Video>`

> **Note**: Do NOT implement `getVideoList`. Use `getSupportedServers` and `getVideos` instead.

## Data Models

### Anime
```javascript
{
    name: "Anime Title",
    link: "/anime/123", // Relative URL usually preferred
    imageUrl: "https://example.com/image.jpg"
}
```

### AnimeDetail
```javascript
{
    name: "Anime Title",
    status: 1, // 0: Ongoing, 1: Completed, 5: Unknown
    author: "Studio/Author",
    description: "Synopsis...",
    genre: ["Action", "Fantasy"],
    episodes: [
        {
            name: "Episode 1",
            url: "/episode/1", // Unique identifier/url for the episode
            dateUpload: "1678888888000" // Milliseconds as string
        }
    ]
}
```

### ServerData
```javascript
{
    id: "server_unique_id",
    name: "Server Name (e.g. VidCloud)",
    isDub: false // true if dub, false if sub
}
```

### Video
```javascript
{
    url: "https://stream.com/video.m3u8",
    quality: "1080p", // or "HLS", "Auto"
    originalUrl: "https://stream.com/video.m3u8",
    { "Referer": "..." } // Optional headers
}
```

## HTML Parsing (DOM Access)

ShonenX provides a **Document Object Model (DOM)** parser similar to web browsers, but adapted for the extension environment.

### Parsing a Document
```javascript
// Parse a full HTML string
const doc = new Document(htmlString);
```

### Selecting Elements

**CSS Selectors:**
```javascript
// Select first matching element
const titleElement = doc.selectFirst("h1.title");
const titleText = titleElement.text;

// Select all matching elements
const items = doc.select("div.item");
items.forEach(item => {
    const link = item.selectFirst("a").attr("href");
});
```

**XPath:**
```javascript
const node = doc.xpathFirst("//div[@class='content']");
```

### Element Properties
Assuming `ele` is an `Element`:
- `ele.text`: Inner text
- `ele.innerHtml`: Inner HTML
- `ele.outerHtml`: Outer HTML (including itself)
- `ele.attr("href")`: Get attribute value
- `ele.hasAttr("class")`: Check if attribute exists
- `ele.selectFirst(...)` / `ele.select(...)`: Sub-selection

## HTTP Requests

Use `this.client` to make requests.

```javascript
// GET request
const response = await this.client.get("https://example.com");
const html = response.body;

// POST request
const postRes = await this.client.post("https://api.example.com", {
    { "Content-Type": "application/json" },
    { key: "value" }
});
```

## Anilist Integration

You can access public Anilist data using the `Anilist` class available in the runtime.

```javascript
/* Usage Example */
const anilist = new Anilist();

// Search
const searchResults = await anilist.searchAnime("Naruto", 1, 20);

// Get Details
const details = await anilist.getAnimeDetails(12345);

// Browse
const trending = await anilist.getTrendingAnime(1, 20);
const popular = await anilist.getPopularAnime(1, 20);
```

### Available Methods

- `searchAnime(title, page, perPage, filter)`
- `getAnimeDetails(animeId)`
- `getTrendingAnime(page, perPage)`
- `getPopularAnime(page, perPage)`
- `getTopRatedAnime(page, perPage)`
- `getRecentlyUpdatedAnime(page, perPage)`
- `getUpcomingAnime(page, perPage)`
- `getMostFavoriteAnime(page, perPage)`
- `getGenres()`
- `getTags()`


## Complete Example

```javascript
class ExampleExtension extends MProvider {
    constructor() {
        super();
        this.client = new Client();
        this.baseUrl = "https://example.com";
    }

    async getPopular(page) {
        const res = await this.client.get(`${this.baseUrl}/popular?page=${page}`);
        const doc = new Document(res.body);
        const list = [];
        
        doc.select("div.anime-card").forEach(el => {
            list.push({
                name: el.selectFirst("h3").text.trim(),
                link: el.selectFirst("a").attr("href"),
                imageUrl: el.selectFirst("img").attr("src")
            });
        });

        return { list, hasNextPage: true };
    }

    // ... other methods ...

    getSupportedServers(animeId, episodeId, episodeNumber) {
        // Assume we fetched servers during getDetail or strictly need to fetch here
        // Ideally, this fetches fresh server list for the episode
        return [{ id: "vidstream", name: "VidStream", isDub: false }];
    }

    async getVideos(animeId, episodeId, serverId, category) {
        const url = `${this.baseUrl}/ajax/get_link?id=${episodeId}&server=${serverId}`;
        const res = await this.client.get(url);
        const data = JSON.parse(res.body);
        
        return [{
            url: data.link,
            quality: "Auto",
            originalUrl: data.link
        }];
    }
}
```
