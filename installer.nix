{ modulesPath, ... }@args:
let
  config = args.config.specialisation.installer.configuration;
  topConfig = args.config;
in
{
  config = {
    specialisation.installer.inheritParentConfig = false;
    specialisation.installer.configuration = {
      imports = [
        ./live-system.nix
        (modulesPath + "/profiles/perlless.nix")
      ];

      nixpkgs.buildPlatform = topConfig.nixpkgs.buildPlatform;
      nixpkgs.hostPlatform = topConfig.nixpkgs.buildPlatform;
      nixpkgs.overlays = topConfig.nixpkgs.overlays;

    };
  };
}
