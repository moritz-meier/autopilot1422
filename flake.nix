{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-24.11";

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
      aarch64System = "aarch64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };

      pkgsCross = import nixpkgs {
        inherit system;
        crossSystem = aarch64System;
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

    in
    {
      ipxe = (pkgs.pkgsCross.aarch64-multiplatform.ipxe.override { embedScript = ./embed.ipxe; });

      devShells.${system} = {
        default = pkgs.mkShell {

          packages = with pkgs; [
            dnsmasq
            matchbox-server
            butane
            miniserve
          ];
        };
      };

      # for `nix fmt`
      formatter.${system} = treefmtEval.config.build.wrapper;

      # for `nix flake check`
      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
