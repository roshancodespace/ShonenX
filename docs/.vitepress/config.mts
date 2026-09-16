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
    footer: {
      message: 'Released under the <a href="https://github.com/roshancodespace/ShonenX/blob/main/LICENSE" target="_blank" rel="noopener">GNU General Public License v3.0</a>.',
      copyright: 'Copyright © 2026-present Roshan (<a href="https://github.com/roshancodespace" target="_blank" rel="noopener">@roshancodespace</a>)'
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Overview', link: '/overview' },
      { text: 'Architecture', link: '/architecture/' },
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
        text: 'Guides',
        items: [
          { text: 'Installation Guide', link: '/guide/installation' },
          { text: 'Extensions Guide', link: '/guide/extensions' }
        ]
      },
      {
        text: 'Architecture',
        items: [
          { text: 'System Overview', link: '/architecture/' },
          { text: 'Data Flow & State', link: '/architecture/data_flow' },
          { text: 'Core Infrastructure', link: '/architecture/infrastructure' }
        ]
      },
      {
        text: 'Features',
        items: [
          { text: 'Media Playback', link: '/features/player' },
          { text: 'Tracking & Sync', link: '/features/tracking' },
          { text: 'Downloads', link: '/features/downloads' }
        ]
      },
      {
        text: 'Source Engine',
        items: [
          { text: 'Overview', link: '/extensions/' },
          { text: 'Extension Bridge', link: '/extensions/bridge' },
          { text: 'Matchmaker', link: '/extensions/matchmaker' }
        ]
      },
      {
        text: 'Development',
        items: [
          { text: 'Local Setup', link: '/development/setup' },
          { text: 'Contributing Guidelines', link: '/development/contributing' }
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
