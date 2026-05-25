{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  nixpkgs.buildPlatform = "x86_64-linux";
  nixpkgs.hostPlatform = "aarch64-linux";

  nixpkgs.overlays = [ (import ./pkgs.nix) ];

  nix.settings = {
    builders-use-substitutes = true;
    trusted-users = [ "root" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  users.mutableUsers = false;
  users.users.root.initialPassword = "root";

  services.openssh.settings.PermitRootLogin = "yes";

  virtualisation.host.pkgs = pkgs.buildPackages;
  virtualisation.cores = 8;
  virtualisation.memorySize = 8096;
  virtualisation.graphics = false;
}
