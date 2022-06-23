{ config, lib, pkgs, mobile-nixos, ... }:

{
  system.build.img-without-firmware = with pkgs; imageBuilder.diskImage.makeGPT {
    name = "nixos";
    diskID = "01234567";
    # headerHole = imageBuilder.size.MiB 16;
    partitions = [
      (imageBuilder.fileSystem.makeESP {
        name = "ESP";
        partitionLabel = "ESP";
        partitionID = "43021685";
        partitionUUID = "CFB21B5C-A580-DE40-940F-B9644B4466E3";
        size = imageBuilder.size.MiB 256;

        populateCommands = ''
          echo "running installBootLoader"
          ${config.system.build.installBootLoader} ${config.system.build.toplevel} -d .
          echo "ran installBootLoader"
        '';
      })
      (imageBuilder.fileSystem.makeExt4 {
        name = "NIXOS_SYSTEM";
        partitionLabel = "NIXOS_SYSTEM";
        partitionID = "5A7FA69C-9394-8144-A74C-6726048B129F";
        partitionUUID = "5A7FA69C-9394-8144-A74C-6726048B129F";
        partitionType = "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1";
        # size = imagBuilder.size.GiB 6;
        populateCommands =
        let
          closureInfo = buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
        in
        ''
          mkdir -p ./nix/store
          echo "Copying system closure..."
          while IFS= read -r path; do
            echo "  Copying $path"
            cp -prf "$path" ./nix/store
          done < "${closureInfo}/store-paths"
          echo "Done copying system closure..."
          cp -v ${closureInfo}/registration ./nix-path-registration
        '';
      })
    ];
  };
  system.build.img = lib.mkDefault config.system.build.img-without-firmware;
  # TODO: pinephone build:
  # system.build.img = pkgs.runCommandNoCC "nixos_full-disk-image.img" {} ''
  #   cp -v ${config.system.build.without-bootloader}/nixos.img $out
  #   chmod +w $out
  #   dd if=${pkgs.tow-boot-pinephone}/Tow-Boot.noenv.bin of=$out bs=1024 seek=8 conv=notrunc
  # '';
}
