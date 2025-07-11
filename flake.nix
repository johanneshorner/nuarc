{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      nuarc-package =
        {
          lib,
          stdenv,
          nushell,
          makeWrapper,
        }:

        stdenv.mkDerivation {
          pname = "nuarc";
          version = self.shortRev or self.dirtyShortRev or "unknown";

          src = ./.;

          nativeBuildInputs = [ makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin
            cp ./nuarc $out/bin/
            wrapProgram $out/bin/nuarc \
              --prefix PATH : ${lib.makeBinPath [ nushell ]}
          '';

          meta = {
            homepage = "https://github.com/johanneshorner/nuarc";
            description = "A nushell script to control aruba switches";
            mainProgram = "nuarc";
          };
        };

      inherit (nixpkgs) lib;
      # Support all Linux systems that the nixpkgs flake exposes
      systems = lib.intersectLists lib.systems.flakeExposed lib.platforms.linux;

      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        system:
        let
          rustic = nixpkgsFor.${system}.callPackage nuarc-package { };
        in
        {
          inherit rustic;
          default = rustic;
          withMount = rustic.override { withMount = true; };
        }
      );

      overlays.default = final: _: {
        rustic = final.callPackage nuarc-package { };
      };
    };
}
