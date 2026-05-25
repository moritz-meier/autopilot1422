{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./vm.nix
  ];

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  fileSystems."/nix/.ro-store" = lib.mkImageMediaOverride {
    fsType = "squashfs";
    device = "../nix-store.squashfs";
    options = [ "loop" ];
    neededForBoot = true;
  };

  fileSystems."/nix/.rw-store" = lib.mkImageMediaOverride {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
    neededForBoot = true;
  };

  fileSystems."/nix/store" = lib.mkImageMediaOverride {
    overlay = {
      lowerdir = [ "/nix/.ro-store" ];
      upperdir = "/nix/.rw-store/store";
      workdir = "/nix/.rw-store/work";
    };
    neededForBoot = true;
  };

  system.build.squashfsStore =
    pkgs.buildPackages.callPackage (pkgs.path + "/nixos/lib/make-squashfs.nix")
      {
        storeContents = [
          config.system.build.toplevel
        ];
        comp = "zstd";
      };

  system.build.liveRamdisk = pkgs.buildPackages.makeInitrdNG {
    inherit (config.boot.initrd) compressor;
    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

    contents = [
      {
        source = config.system.build.squashfsStore;
        target = "/nix-store.squashfs";
      }
    ];
  };

  system.build.efi = pkgs.buildPackages.runCommand "efi" { } ''
    mkdir $out
    ${pkgs.buildPackages.systemdUkify}/bin/ukify --help
  '';

  qemuUbootVM.bootEfi = "${config.system.build.efi}/nixos.efi";

  users.mutableUsers = false;
  users.users.root.initialPassword = "root";

  services.getty.autologinUser = "root";
}
