{ config, ... }:
{
  sane.persist.sys.byStore.cryptClearOnBoot = [
    # when running commands as root, some things may create ~/.cache entries.
    # notably:
    # - `/root/.cache/nix/` takes up ~10 MB on lappy/desko/servo
    # - `/root/.cache/mesa_shader_cache` takes up 1-2 MB on moby
    { path = "/root"; user = "root"; group = "root"; mode = "0700"; }
  ];

  sane.users.root = {
    home = "/root";
    fs.".ssh/nixremote".symlink.target = config.sops.secrets."nixremote_ssh_key".path;
    fs.".ssh/nixremote.pub".symlink.text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4KI7I2w5SvXRgUrXYiuBXPuTL+ZZsPoru5a2YkIuCf";
    fs.".ssh/config".symlink.text = ''
      # root -> <other nix host> happens for remote builds
      # provide the auth, and instruct which remote user to login as:
      Host desko
        # Prevent using ssh-agent or another keyfile
        IdentitiesOnly yes
        IdentityFile /root/.ssh/nixremote
        User nixremote
      Host servo
        # Prevent using ssh-agent or another keyfile
        IdentitiesOnly yes
        IdentityFile /root/.ssh/nixremote
        User nixremote
    '';
  };
}
