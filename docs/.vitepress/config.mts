import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "ShonenX",
  description: "Official documentation and guides for ShonenX.",
  base: '/ShonenX/',
  cleanUrls: true,
  head: [
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }],
    ['link', { href: 'https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,100..900;1,100..900&display=swap', rel: 'stylesheet' }]
  ],
  themeConfig: {
    logo: '/app_icon.png',
    lastUpdated: {
      text: 'Last updated',
      formatOptions: {
        dateStyle: 'medium'
      }
    },
    editLink: {
      pattern: 'https://github.com/roshancodespace/ShonenX/edit/main/docs/:path',
      text: 'Edit this page'
    },
    footer: {
      message: 'Released under the <a href="https://github.com/roshancodespace/ShonenX/blob/main/LICENSE" target="_blank" rel="noopener">GNU General Public License v3.0</a>.',
      copyright: 'Copyright © 2026-present Roshan (<a href="https://github.com/roshancodespace" target="_blank" rel="noopener">@roshancodespace</a>)'
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Setup', link: '/setup/' },
      { text: 'Contributing', link: '/contributing/' },
      { text: 'Donate', link: 'https://www.buymeacoffee.com/roshan.codespace' }
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Overview', link: '/overview' }
        ]
      },
      {
        text: 'User Guides',
        items: [
          { text: 'Installation', link: '/guide/installation' },
          { text: 'Extensions', link: '/guide/extensions' }
        ]
      },
      {
        text: 'Developer Setup',
        items: [
          { text: 'Local Build', link: '/setup/' },
          { text: 'Architecture', link: '/setup/architecture' }
        ]
      },
      {
        text: 'Core Concepts',
        items: [
          { text: 'State', link: '/core/state' },
          { text: 'Data', link: '/core/data' },
          { text: 'Routing', link: '/core/routing' }
        ]
      },
      {
        text: 'Key Systems',
        items: [
          { text: 'Source Engine', link: '/systems/source_engine' },
          { text: 'Tracking', link: '/systems/tracking' },
          { text: 'Player & Downloads', link: '/systems/player_and_downloads' }
        ]
      },
      {
        text: 'Contributing',
        items: [
          { text: 'Guidelines', link: '/contributing/' },
          { text: 'Common Tasks', link: '/contributing/common_tasks' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/roshancodespace/shonenx' },
      { icon: 'discord', link: 'https://discord.gg/uJyXZYSmH4' }
    ],

    search: {
      provider: 'local'
    }
  }
})
