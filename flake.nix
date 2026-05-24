{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        overlays = [ (import ./pkgs.nix) ];
      };

      pkgsAarch64 = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ (import ./pkgs.nix) ];
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      packages = {
        "${system}" = {
          foo = pkgs.pkgsCross.aarch64-multiplatform.buildPackages.foo;
        };
        "aarch64-linux" = {
          foo = pkgsAarch64.foo;
        };
      };

      nixosConfigurations = {
        autopilot1422 = nixpkgs.lib.nixosSystem {
          modules = [
            ./autopilot1422.nix
            ./installer.nix
          ];
        };
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [
            pkgs.miniserve
            pkgs.qemu_full
            pkgs.foo
          ];
        };
      };

      # for `nix fmt`
      formatter.${system} = treefmtEval.config.build.wrapper;

      # for `nix flake check`
      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
