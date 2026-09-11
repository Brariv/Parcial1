{
  description = "A nix flake for c projects and environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      flake = {
        templates.default.path = ./.;
      };

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            libc
          ];

        in
        {

          devShells.default = pkgs.mkShell {
            inherit nativeBuildInputs buildInputs;
            packages = with pkgs; [
              clang-tools
              lldb

              compiledb
              makeWrapper
              autotools-language-server
            ];

          };
        };

    };
}
