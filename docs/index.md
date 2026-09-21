---
layout: home

hero:
  name: "ShonenX"
  text: "Developer Documentation"
  image:
    src: /hero_mockup.jpg
  tagline: "An implementation-driven guide to modifying, extending, and understanding the ShonenX Flutter application."
  actions:
    - theme: brand
      text: User Installation
      link: /guide/installation
    - theme: alt
      text: Extensions Guide
      link: /guide/extensions
    - theme: alt
      text: Developer Docs
      link: /setup/

features:
  - title: Riverpod State
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>'
    details: Learn our strict Riverpod dependency and state management patterns.
    link: /core/state
  - title: Tracker Integration
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 21v-5h5"/></svg>'
    details: Discover how media progress syncs with AniList, MAL, and others.
    link: /systems/tracking
  - title: Source Engine
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/></svg>'
    details: Trace the request flow through the JS Extension Bridge.
    link: /systems/source_engine
  - title: Native Media
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="10 8 16 12 10 16 10 8"/></svg>'
    details: Dive into the native video player and local P2P torrent streaming.
    link: /systems/player_and_downloads
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
    margin: -24px auto 32px auto !important;
    order: 1 !important;
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

Whether you are a regular user or a contributor, here is how you can navigate ShonenX:

*   **Users:** Start with the [Installation Guide](/guide/installation) and learn how to add sources via the [Extensions Setup](/guide/extensions).
*   **Developers:** Start with [Local Build Setup](/setup/) if you need to compile the project.
*   **Developers:** Read the [Architecture Walkthrough](/setup/architecture) to understand where files belong, and trace data flows using the **Core Concepts** and **Key Systems** links in the sidebar.
