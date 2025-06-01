{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=master";

    xlnx.url = "github:moritz-meier/xilinx-nix-utils?ref=staging";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      xlnx,
      treefmt-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      overlays = [
        xlnx.overlays.default
        xlnx.overlays.zynq-srcs
        xlnx.overlays.zynq-utils
        xlnx.overlays.zynq-boards

        (final: prev: {
          zynq-srcs = prev.zynq-srcs // {
            uboot-src = pkgs.fetchFromGitHub {
              owner = "Xilinx";
              repo = "u-boot-xlnx";
              rev = "xlnx_rebase_v2025.01";
              hash = "sha256-RTcd7MR37E4yVGWP3RMruyKBI4tz8ex7mY1f5F2xd00=";
            };
          };
        })
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

    in
    rec {
      packages.${system} =
        let
          board = pkgs.zynq-boards.kria-kr260.overrideAttrs (
            final: prev: {

              linux-dt = prev.linux-dt.override {
                extraDtsi = ./board.dtsi;
              };

              uboot = prev.uboot.override (prev: {
                extraConfig =
                  prev.extraConfig
                  + ''
                    CONFIG_NET_LWIP=y
                  '';
              });
            }
          );
        in
        {
          fw = board.boot-image;
          uboot = board.uboot;
          boot = board.boot-jtag;
          flash = board.flash-qspi;

          netboot = pkgs.callPackage ./netboot.nix { } {
            baseUrl = "http://192.168.178.20:8080";
            nixosSystem = nixosConfigurations.autopilot1422;
            ipxe = pkgs.pkgsCross.aarch64-multiplatform.ipxe;
          };
        };

      nixosConfigurations.autopilot1422 = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          flakeRoot = ./.;
        };
        modules = [
          (
            {
              modulesPath,
              ...
            }:
            {
              imports = [
                (modulesPath + "/installer/netboot/netboot.nix")
              ];

              nixpkgs.buildPlatform = "x86_64-linux";
              nixpkgs.hostPlatform = "aarch64-linux";
            }
          )
        ];
      };

      devShells.${system} = {
        default = pkgs.mkShell {

          packages = with pkgs; [
            dtc
            dnsmasq
            miniserve
            xilinx-unified
          ];
        };
      };

      # for `nix fmt`
      formatter.${system} = treefmtEval.config.build.wrapper;

      # for `nix flake check`
      checks.${system}.formatting = treefmtEval.config.build.check self;
    };
}
