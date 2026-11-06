{
  description = "ShonenX - Read. Watch. Track.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (
          system: f nixpkgs.legacyPackages.${system}
        );
    in {
      packages = forAllSystems (pkgs: rec {
        shonenx = pkgs.callPackage ./nix/package.nix { };
        default = shonenx;
      });

      overlays.default = final: _prev: {
        shonenx = final.callPackage ./nix/package.nix { };
      };
    };
}
