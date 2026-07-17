# ShonenX DSL

Build Anime, Manga, and Tracker providers using JSON.

The ShonenX DSL (Domain Specific Language) allows extensions to be written entirely in JSON without Flutter, Dart, or native code. Providers are loaded and executed at runtime, making them easy to develop, distribute, and update independently from the app.

---

## What Is a Provider?

A provider is a JSON file that describes:

- Metadata (name, version, icon, etc.)
- Supported methods
- Request pipelines
- Data extraction logic

Example:

```json
{
  "id": "gogoanime",
  "name": "GogoAnime",
  "version": "1.0.0",
  "mediaType": "ANIME",
  "baseUrl": "https://gogoanime3.co",
  "iconUrl": "https://gogoanime3.co/img/icon.png",
  "methods": {}
}
```

---

# How The DSL Works

Every method is executed as a pipeline.

A pipeline is simply a list of steps.

```text
Request → Parse → Extract → Transform → Return
```

Example:

```json
[
  {
    "type": "get",
    "url": "{{baseUrl}}/search?q={{query}}"
  },
  {
    "type": "html"
  },
  {
    "type": "select",
    "selector": ".card",
    "all": true
  }
]
```

Each step receives the output from the previous step.

The current value is always available as:

```text
lastOutput
```

Think of `lastOutput` as "whatever the previous step returned".

---

# Provider Types

ShonenX currently supports three provider types.

## Anime

Anime providers expose streaming content.

Required methods:

| Method | Description |
|----------|----------|
| search | Search anime |
| trending | Trending or popular anime |
| details | Anime metadata |
| episodes | Episode list |
| servers | Streaming servers |
| sources | Video sources |

Execution flow:

```text
search
  └─► details
         └─► episodes
                └─► servers
                       └─► sources
```

---

## Manga

Manga providers expose chapter-based content.

Required methods:

| Method | Description |
|----------|----------|
| search | Search manga |
| trending | Trending or popular manga |
| details | Manga metadata |
| chapters | Chapter list |
| pages | Chapter pages |

Execution flow:

```text
search
  └─► details
         └─► chapters
                └─► pages
```

---

## Tracker

Tracker providers integrate services such as MyAnimeList or AniList.

Common methods:

| Method | Description |
|----------|----------|
| fetchProfile | Current user profile |
| searchMedia | Search media |
| fetchLibrary | User library |
| fetchEntry | Single entry |
| updateEntry | Update progress/status |
| removeEntry | Remove entry |

Tracker implementations may define additional methods.

---

# Runtime Variables

Depending on which method is being executed, ShonenX automatically injects variables into the execution context.

## Search

```json
{
  "query": "naruto",
  "page": 1
}
```

Available variables:

```text
query
page
```

---

## Trending

```json
{
  "page": 1
}
```

Available variables:

```text
page
```

---

## Details

```json
{
  "id": "/category/naruto"
}
```

Available variables:

```text
id
```

---

## Episodes

```text
animeId
```

---

## Servers

```text
episodeId
```

---

## Sources

```text
serverId
```

---

## Chapters

```text
mangaId
```

---

## Pages

```text
chapterId
```

---

# Execution Context

Besides runtime variables, the following values are always available.

| Variable | Description |
|-----------|-----------|
| baseUrl | Provider base URL |
| lastOutput | Output of previous step |

You may also create your own variables using `output`.

Example:

```json
{
  "type": "select",
  "selector": ".anime-card",
  "all": true,
  "output": "items"
}
```

Later:

```json
{
  "type": "map",
  "input": "{{items}}"
}
```

---

# Pipeline Steps

## Network

### get

Performs an HTTP GET request.

```json
{
  "type": "get",
  "url": "{{baseUrl}}/search?q={{query}}"
}
```

Properties:

| Property | Required |
|-----------|-----------|
| url | Yes |
| headers | No |
| output | No |

---

### post

Performs an HTTP POST request.

```json
{
  "type": "post",
  "url": "{{baseUrl}}/api/search",
  "body": {
    "query": "{{query}}"
  }
}
```

Properties:

| Property | Required |
|-----------|-----------|
| url | Yes |
| body | No |
| headers | No |
| output | No |

---

## Parsing

### html

Parses a string into an HTML document.

```json
{
  "type": "html"
}
```

Output:

```text
Document
```

---

### json

Parses a string into a JSON object.

```json
{
  "type": "json"
}
```

Output:

```text
Map / List
```

---

## Extraction

### select

Queries HTML using CSS selectors.

```json
{
  "type": "select",
  "selector": ".card"
}
```

Properties:

| Property | Description |
|-----------|-----------|
| selector | CSS selector |
| all | Return all matches |
| text | Extract text |
| html | Extract HTML |
| attr | Extract attribute |
| input | Custom source |

Examples:

```json
{
  "type": "select",
  "selector": "img",
  "attr": "src"
}
```

```json
{
  "type": "select",
  "selector": "h1",
  "text": true
}
```

---

### path

Extracts values from JSON structures.

```json
{
  "type": "path",
  "path": "data.items[0].title"
}
```

---

### regex

Extracts text using a regular expression.

```json
{
  "type": "regex",
  "pattern": "episode-(\\d+)"
}
```

---

## Transformation

### object

Creates a new object.

```json
{
  "type": "object",
  "fields": {
    "id": "{{item.id}}",
    "title": "{{item.title}}"
  }
}
```

---

### map

Runs a nested pipeline for each item in a list.

```json
{
  "type": "map",
  "input": "{{items}}",
  "itemVar": "item",
  "steps": []
}
```

Properties:

| Property | Description |
|-----------|-----------|
| input | Source list |
| itemVar | Current item variable |
| steps | Nested pipeline |

---

### transform

Evaluates a helper expression.

```json
{
  "type": "transform",
  "expression": "lowercase(lastOutput)"
}
```

---

### return

Stops execution immediately and returns a value.

```json
{
  "type": "return",
  "value": "{{lastOutput}}"
}
```

---

# Template Expressions

Any string containing:

```text
{{ expression }}
```

will be evaluated dynamically.

Examples:

```text
{{query}}

{{title}}

{{trim(title)}}

{{absoluteUrl(baseUrl, href)}}

{{parseInt(number)}}
```

Nested expressions are supported:

```text
{{lowercase(trim(title))}}
```

---

# Helper Functions

Helpers can be used anywhere inside template expressions.

## Network

```js
fetch(url, headers?)
get(url, headers?)
post(url, body?, headers?)
```

---

## HTML

```js
select(element, selector)
selectAll(element, selector)
text(element)
html(element)
attr(element, attribute)
exists(element, selector)
```

Example:

```text
{{text(select(item, '.title'))}}
```

---

## JSON

```js
jsonPath(object, path)
```

---

## String Helpers

```js
trim(value)
replace(value, pattern, replacement)
split(value, separator)
regex(value, pattern, groupIndex?)
lowercase(value)
uppercase(value)
```

---

## URL Helpers

```js
absoluteUrl(baseUrl, relativeUrl)
joinUrl(part1, part2)
```

---

## Collection Helpers

```js
first(list)
last(list)
filter(list, key, value)
flatten(list)
```

---

## Number Helpers

```js
parseInt(value)
parseDouble(value)
```

---

## Utility Helpers

```js
cache(key, value?)
variable(name, value?)
log(value)
```

---

# Common Patterns

## HTML Scraping

```json
[
  {
    "type": "get",
    "url": "{{baseUrl}}/search?q={{query}}"
  },
  {
    "type": "html"
  },
  {
    "type": "select",
    "selector": ".card",
    "all": true
  },
  {
    "type": "map",
    "steps": []
  }
]
```

---

## JSON API

```json
[
  {
    "type": "get",
    "url": "{{baseUrl}}/api/search?q={{query}}"
  },
  {
    "type": "json"
  },
  {
    "type": "path",
    "path": "data"
  },
  {
    "type": "map",
    "steps": []
  }
]
```

---

# Best Practices

### Prefer APIs Over Scraping

If a website exposes a JSON API, use it whenever possible.

Benefits:

- Faster
- More reliable
- Easier to maintain

---

### Use Stable IDs

Good:

```json
{
  "id": "/category/naruto"
}
```

Bad:

```json
{
  "id": "Naruto"
}
```

IDs should not change when titles change.

---

### Resolve Relative URLs

Good:

```text
{{absoluteUrl(baseUrl, href)}}
```

Bad:

```text
{{href}}
```

---

### Store Reusable Values

```json
{
  "type": "select",
  "selector": ".item",
  "all": true,
  "output": "items"
}
```

Avoid repeating expensive operations when a value can be stored once.

---

# Examples

Complete examples are included with ShonenX:

- [sample_anime.json](examples/dsl_providers/sample_anime.json)
- [sample_manga.json](examples/dsl_providers/sample_manga.json)
- [sample_tracker.json](examples/dsl_providers/sample_tracker.json)

Reading real providers is the fastest way to learn the DSL.