---
layout: home

hero:
  name: "ShonenX"
  text: "Open Source Ecosystem"
  image:
    src: /hero_mockup.jpg
  tagline: "A beautifully crafted, developer-focused platform offering advanced tracking, episode scheduling, and a seamless native experience."
  actions:
    - theme: brand
      text: Get Started
      link: /guide/installation
    - theme: alt
      text: Developer Docs
      link: /architecture/
    - theme: alt
      text: GitHub Repository
      link: https://github.com/roshancodespace/shonenx

features:
  - title: Developer First
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>'
    details: Strict code boundaries and modular Riverpod architecture designed to simplify open-source contributions.
  - title: Advanced Tracking
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 21v-5h5"/></svg>'
    details: Automatic progress synchronization with AniList, MyAnimeList, Simkl, and Kitsu.
  - title: Schedule Reminders
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>'
    details: Never miss an update with built-in episode reminder scheduling and notifications.
  - title: Cross Platform
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="9" x2="9" y1="21" y2="9"/></svg>'
    details: Enjoy a seamless, native Flutter experience across Android, Windows, and Linux devices.
---

<style>
.VPHero .image-container {
  width: 100% !important;
  max-width: 200px !important;
  height: auto !important;
  max-height: none !important;
  position: relative !important;
  transform: none !important;
  margin: 0 auto;
}

.VPHero .image-bg {
  display: none !important;
}

.VPHero .VPImage {
  position: static !important;
  border-radius: 18px;
  border: 5px solid #1a1a1a;
  box-shadow: 0 20px 40px rgba(0,0,0,0.4), 0 0 0 1px #333;
  width: 100% !important;
  height: auto !important;
  max-height: none !important;
  transform: perspective(1000px) rotateY(-15deg) rotateX(5deg) !important;
  transition: transform 0.4s ease, box-shadow 0.4s ease !important;
  display: block;
}

.VPHero .VPImage:hover {
  transform: perspective(1000px) rotateY(-5deg) rotateX(2deg) !important;
  box-shadow: 0 30px 60px rgba(0,0,0,0.5), 0 0 0 1px #444;
}

@media (max-width: 959px) {
  .VPHero .image {
    margin: -24px auto 32px auto !important; /* Pull up to navbar, push down from text */
    order: 1 !important; /* Ensure image is above text */
  }
  .VPHero .image-container {
    max-width: 140px !important;
    margin: 0 auto !important;
  }
  .VPHero .VPImage {
    transform: none !important;
    border-radius: 12px;
    border-width: 4px;
    margin: 0 auto;
  }
  .VPHero .VPImage:hover {
    transform: none !important;
  }
}

.dark .VPHero .VPImage {
  border-color: #000;
  box-shadow: 0 20px 40px rgba(0,0,0,0.8), 0 0 0 1px #222;
}

.dark .VPHero .VPImage:hover {
  box-shadow: 0 30px 60px rgba(0,0,0,0.9), 0 0 0 1px #333;
}

</style>

## Getting Started

New to the project? Start with the [Installation Guide](/guide/installation) and [Extensions Guide](/guide/extensions). Developers can check out the [Architecture Overview](/architecture/) and read the [Contributing Guidelines](/development/contributing) to understand our boundaries.

::: warning Disclaimer
ShonenX is an open-source tool that aggregates content from third-party sources. We do not host, store, or distribute any copyrighted media. The developers have no control over and are not responsible for the content provided by third-party extensions. Users are solely responsible for the extensions they install and the content they access.
:::
