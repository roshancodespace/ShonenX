---
layout: home

hero:
  name: "ShonenX"
  text: "Developer Documentation"
  image:
    src: /hero_mockup.jpg
  tagline: "A unified, cross-platform Anime & Manga client built with Flutter. Combining the best ideas from across the open-source ecosystem with Rust networking, encrypted DoH, and native mpv playback."
  actions:
    - theme: brand
      text: Get the App
      link: /guide/installation
    - theme: alt
      text: Extensions Setup
      link: /guide/extensions
    - theme: alt
      text: Developer Docs
      link: /setup/

features:
  - title: Encrypted DoH & Rust
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>'
    details: Avoid ISP DNS hijacking and Cloudflare TLS fingerprinting using Rust rhttp and DNS over HTTPS.
    link: /systems/dns_over_https
  - title: Multi-Ecosystem Bridge
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/></svg>'
    details: Run extensions from Mangayomi, Cloudstream, and Aniyomi natively inside one unified Flutter engine.
    link: /systems/source_engine
  - title: Native Media & Torrents
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="10 8 16 12 10 16 10 8"/></svg>'
    details: Hardware-accelerated mpv core with styled ASS subtitles and sequential P2P torrent streaming.
    link: /systems/player_and_downloads
  - title: Riverpod Architecture
    icon: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>'
    details: Strict feature boundaries, reactive state management, automatic resource cleanup, and Isar caching.
    link: /core/state
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

Whether you are looking to run the app or contribute code, here is where to start:

*   **Users:** Read the [Installation Guide](/guide/installation) and check the [Extensions Guide](/guide/extensions) for repo setup.
*   **Developers:** Check out the [Local Setup Guide](/setup/) to get Flutter, Rust, and desktop prerequisites compiling cleanly.
*   **Architecture:** Walk through the [Architecture Walkthrough](/setup/architecture) to understand the layer rules, and explore the **Key Systems** in the sidebar to see how DoH, Stream Proxying, and Multi-Tracker Sync work.
