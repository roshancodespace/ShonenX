class DslTemplates {
  static const String anime = r'''{
  "id": "sample_anime",
  "name": "Sample Anime DSL",
  "version": "1.0.0",
  "mediaType": "ANIME",
  "baseUrl": "https://gogoanime3.co",
  "iconUrl": "https://gogoanime3.co/img/icon.png",
  "methods": {
    "search": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/filter.html?keyword={{query}}&page={{page}}"
        },
        {
          "type": "html"
        },
        {
          "type": "select",
          "selector": "ul.items li",
          "all": true,
          "output": "items"
        },
        {
          "type": "map",
          "input": "{{items}}",
          "itemVar": "item",
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{attr(select(item, 'p.name a'), 'href')}}",
                "title": "{{text(select(item, 'p.name a'))}}",
                "cover": "{{attr(select(item, 'div.img img'), 'src')}}"
              }
            }
          ]
        }
      ]
    },
    "trending": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/popular.html?page={{page}}"
        },
        {
          "type": "html"
        },
        {
          "type": "select",
          "selector": "ul.items li",
          "all": true,
          "output": "items"
        },
        {
          "type": "map",
          "input": "{{items}}",
          "itemVar": "item",
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{attr(select(item, 'p.name a'), 'href')}}",
                "title": "{{text(select(item, 'p.name a'))}}",
                "cover": "{{attr(select(item, 'div.img img'), 'src')}}"
              }
            }
          ]
        }
      ]
    },
    "details": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}{{id}}"
        },
        {
          "type": "html"
        },
        {
          "type": "object",
          "fields": {
            "id": "{{id}}",
            "title": "{{text(select(null, 'div.anime_info_body_bg h1'))}}",
            "cover": "{{attr(select(null, 'div.anime_info_body_bg img'), 'src')}}",
            "description": "{{text(select(null, 'p.type:nth-of-type(2)'))}}"
          }
        }
      ]
    },
    "episodes": {
      "steps": [
        {
          "type": "get",
          "url": "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=100&id={{animeId}}"
        },
        {
          "type": "html"
        },
        {
          "type": "select",
          "selector": "#episode_related li",
          "all": true,
          "output": "epList"
        },
        {
          "type": "map",
          "input": "{{epList}}",
          "itemVar": "item",
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{attr(select(item, 'a'), 'href')}}",
                "number": "{{parseInt(text(select(item, 'div.name')))}}",
                "title": "{{trim(text(select(item, 'div.name')))}}"
              }
            }
          ]
        }
      ]
    },
    "servers": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}{{episodeId}}"
        },
        {
          "type": "html"
        },
        {
          "type": "select",
          "selector": "div.anime_muti_link ul li",
          "all": true,
          "output": "serverList"
        },
        {
          "type": "map",
          "input": "{{serverList}}",
          "itemVar": "item",
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{attr(select(item, 'a'), 'data-video')}}",
                "name": "{{text(select(item, 'a'))}}",
                "type": "sub"
              }
            }
          ]
        }
      ]
    },
    "sources": {
      "steps": [
        {
          "type": "object",
          "fields": {
            "url": "{{serverId}}",
            "quality": "Auto"
          }
        },
        {
          "type": "return",
          "value": [
            "{{lastOutput}}"
          ]
        }
      ]
    }
  }
}''';

  static const String manga = r'''{
  "id": "sample_manga",
  "name": "Sample Manga DSL",
  "version": "1.0.0",
  "mediaType": "MANGA",
  "baseUrl": "https://api.mangadex.org",
  "iconUrl": "https://mangadex.org/favicon.ico",
  "methods": {
    "search": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/manga?title={{query}}&limit=10"
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
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{item.id}}",
                "title": "{{item.attributes.title.en}}",
                "description": "{{item.attributes.description.en}}"
              }
            }
          ]
        }
      ]
    },
    "trending": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/manga?limit=10&order[followedCount]=desc"
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
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{item.id}}",
                "title": "{{item.attributes.title.en}}"
              }
            }
          ]
        }
      ]
    },
    "details": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/manga/{{id}}"
        },
        {
          "type": "json"
        },
        {
          "type": "path",
          "path": "data"
        },
        {
          "type": "object",
          "fields": {
            "id": "{{lastOutput.id}}",
            "title": "{{lastOutput.attributes.title.en}}",
            "description": "{{lastOutput.attributes.description.en}}"
          }
        }
      ]
    },
    "chapters": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/manga/{{mangaId}}/feed?translatedLanguage[]=en&limit=100"
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
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{item.id}}",
                "number": "{{parseDouble(item.attributes.chapter)}}",
                "title": "{{item.attributes.title}}"
              }
            }
          ]
        }
      ]
    },
    "pages": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/at-home/server/{{chapterId}}"
        },
        {
          "type": "json"
        },
        {
          "type": "path",
          "path": "chapter.data"
        },
        {
          "type": "map",
          "itemVar": "fileName",
          "steps": [
            {
              "type": "object",
              "fields": {
                "url": "https://uploads.mangadex.org/data/{{chapterId}}/{{fileName}}"
              }
            }
          ]
        }
      ]
    }
  }
}''';

  static const String tracker = r'''{
  "id": "sample_tracker",
  "name": "Sample Tracker DSL",
  "version": "1.0.0",
  "mediaType": "TRACKER",
  "baseUrl": "https://api.myanimelist.net/v2",
  "iconUrl": "https://myanimelist.net/favicon.ico",
  "methods": {
    "fetchProfile": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/users/@me",
          "headers": {
            "Authorization": "Bearer {{accessToken}}"
          }
        },
        {
          "type": "json"
        },
        {
          "type": "object",
          "fields": {
            "name": "{{name}}",
            "avatarUrl": "{{picture}}"
          }
        }
      ]
    },
    "searchMedia": {
      "steps": [
        {
          "type": "get",
          "url": "{{baseUrl}}/anime?q={{query}}&limit=10",
          "headers": {
            "Authorization": "Bearer {{accessToken}}"
          }
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
          "steps": [
            {
              "type": "object",
              "fields": {
                "id": "{{item.node.id}}",
                "title": "{{item.node.title}}",
                "cover": "{{item.node.main_picture.medium}}"
              }
            }
          ]
        }
      ]
    }
  }
}''';
}
