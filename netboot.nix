{ runCommand, writeTextFile }:

{
  baseUrl,
  nixosSystem,
  ipxe,
}:

let
  ipxeScript = writeTextFile {
    name = "ipxe-netboot-script";
    text = ''
      #!ipxe

      :retry_dhcp
      dhcp || goto retry_dhcp

      kernel ${baseUrl}/kernel init=${nixosSystem.config.system.build.toplevel}/init
      initrd ${baseUrl}/initrd
      boot
    '';
  };

  customIpxe = ipxe.override {
    embedScript = ipxeScript;
  };
in

runCommand "netboot" { } ''
  mkdir $out

  ln -s ${customIpxe}/ipxe.efi $out/ipxe.efi
  ln -s ${nixosSystem.config.boot.kernelPackages.kernel}/Image $out/kernel
  ln -s ${nixosSystem.config.system.build.netbootRamdisk}/initrd $out/initrd
''
