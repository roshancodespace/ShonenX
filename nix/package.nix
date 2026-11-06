{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  gtk3,
  glib,
  glib-networking,
  atk,
  cairo,
  pango,
  harfbuzz,
  gdk-pixbuf,
  libepoxy,
  fontconfig,
  freetype,
  fribidi,
  xz,
  zlib,
  alsa-lib,
  libglvnd,
  webkitgtk_4_1,
  libsoup_3,
  libva,
  libvdpau,
  libdrm,
  libgbm,
  gnutls,
  libunwind,
  lcms2,
  libarchive,
  libpulseaudio,
  wayland,
  libxkbcommon,
  libx11,
  libxcb,
  libxext,
  libxfixes,
  libxrandr,
  libxscrnsaver,
  libxv,
  xdg-user-dirs,
  xdg-utils,
  adwaita-icon-theme,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "shonenx";
  version = "2.1.5";

  src = fetchurl {
    url = "https://github.com/roshancodespace/ShonenX/releases/download/v${finalAttrs.version}/ShonenX-Linux.zip";
    hash = "sha256-llwV7tKMTviC0q+pdrsaJXvIXblyISHZwnE/tOzr+Ww=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    adwaita-icon-theme
    glib-networking
    gtk3
    glib
    atk
    cairo
    pango
    harfbuzz
    gdk-pixbuf
    libepoxy
    fontconfig
    freetype
    fribidi
    xz
    zlib
    alsa-lib
    libglvnd
    webkitgtk_4_1
    libsoup_3
    libva
    libvdpau
    libdrm
    libgbm
    gnutls
    libunwind
    lcms2
    libarchive
    libpulseaudio
    wayland
    libxkbcommon
    libx11
    libxcb
    libxext
    libxfixes
    libxrandr
    libxscrnsaver
    libxv
  ];

  dontUnpack = true;
  dontWrapGApps = true; # wrapper args are passed to makeWrapper in postFixup

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/shonenx
    unzip -q $src -d $out/lib/shonenx
    chmod +x $out/lib/shonenx/shonenx

    # Reuse the Flatpak packaging files that already live in this repo
    install -Dm644 ${../flatpak/com.roshancodespace.shonenx.desktop} \
      $out/share/applications/com.roshancodespace.shonenx.desktop
    install -Dm644 ${../flatpak/com.roshancodespace.shonenx.png} \
      $out/share/icons/hicolor/256x256/apps/com.roshancodespace.shonenx.png
    install -Dm644 ${../flatpak/com.roshancodespace.shonenx.metainfo.xml} \
      $out/share/metainfo/com.roshancodespace.shonenx.metainfo.xml

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/lib/shonenx/shonenx $out/bin/shonenx \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [xdg-user-dirs xdg-utils]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libglvnd]}:$out/lib/shonenx/lib:/run/opengl-driver/lib
  '';

  meta = {
    description = "Minimal yet feature-rich anime and manga client";
    homepage = "https://github.com/roshancodespace/ShonenX";
    changelog = "https://github.com/roshancodespace/ShonenX/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "shonenx";
  };
})
