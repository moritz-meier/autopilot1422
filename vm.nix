{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.qemuUbootVM = {

    bootEfi = lib.mkOption {
      type = with lib.types; path;
    };

    extraQemuArgs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = {
    system.build.qemuUbootVM = pkgs.buildPackages.writeShellScript "run-qemu-uboot-vm" ''

      esp=$(mktemp -d)
      mkdir -p $esp/EFI/BOOT
      cp ${config.qemuUbootVM.bootEfi} $esp/EFI/BOOT/BOOTAA64.EFI

      ${pkgs.buildPackages.qemu_full}/bin/qemu-system-aarch64 \
        -machine virt\
        -cpu cortex-a53 \
        -smp 4 \
        -m size=2G \
        -nographic \
        -bios ${pkgs.ubootQemuAarch64}/u-boot.bin \
        -drive format=raw,media=disk,file=fat:rw:$esp \
        ${lib.concatStringsSep "\ \n" config.qemuUbootVM.extraQemuArgs}
        "''${@}"
    '';
  };
}

# foo=$(mktemp -d)
# mkdir -p $foo/efi/boot
# cp ${config.system.build.uki}/nixos.efi $foo/efi/boot/bootaa64.efi

# ${pkgs.buildPackages.qemu_full}/bin/qemu-img create -f qcow2 /dev/shm/test-disk.qcow2 32G

# -drive format=qcow2,file=/dev/shm/test-disk.qcow2,if=virtio \
# -drive format=raw,media=disk,file=fat:rw:$foo \
# -net user,hostfwd=tcp::2222-:22 -net nic \
