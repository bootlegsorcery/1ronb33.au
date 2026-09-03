{
  description = "1ronb33.au — In Loving Memory of 1RON & B33";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
      tools = pkgs: [
        pkgs.hugo
        pkgs.tailwindcss_3
      ];
    in
    {
      packages = forAllSystems (
        system:
        let pkgs = pkgsFor system; in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "1ronb33.au";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = tools pkgs;
            buildPhase = ''
              runHook preBuild
              HOME="$TMPDIR" hugo --minify --destination public
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              cp -r public/. "$out/"
              runHook postInstall
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let pkgs = pkgsFor system; in
        {
          default = pkgs.mkShell { packages = tools pkgs; };
        }
      );

      apps = forAllSystems (
        system:
        let pkgs = pkgsFor system; in
        {
          serve = {
            type = "app";
            program = "${pkgs.writeShellScript "serve" ''
              export PATH="${pkgs.lib.makeBinPath (tools pkgs)}:$PATH"
              exec ${pkgs.hugo}/bin/hugo server "$@"
            ''}";
          };
          default = self.apps.${system}.serve;
        }
      );

      checks = forAllSystems (system: {
        site = self.packages.${system}.default;
      });
    };
}