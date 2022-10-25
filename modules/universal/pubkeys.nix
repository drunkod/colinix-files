# create ssh key by running:
# - `ssh-keygen -t ed25519`
let
  withHost = host: key: "${host} ${key}";
  withUser = user: key: "${key} ${user}";

  keys = rec {
    lappy = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSJnqmVl9/SYQ0btvGb0REwwWY8wkdkGXQZfn/1geEc";
      users.colin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDpmFdNSVPRol5hkbbCivRhyeENzb9HVyf9KutGLP2Zu";
    };
    desko = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFw9NoRaYrM6LbDd3aFBc4yyBlxGQn8HjeHd/dZ3CfHk";
      users.colin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU5GlsSfbaarMvDA20bxpSZGWviEzXGD8gtrIowc1pX";
    };
    servo = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfdSmFkrVT6DhpgvFeQKm3Fh9VKZ9DbLYOPOJWYQ0E8";
      users.colin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS1qFzKurAdB9blkWomq8gI1g0T3sTs9LsmFOj5VtqX";
    };
    moby = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO1N/IT3nQYUD+dBlU1sTEEVMxfOyMkrrDeyHcYgnJvw";
      users.colin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrR+gePnl0nV/vy7I5BzrGeyVL+9eOuXHU1yNE3uCwU";
    };

    "uninsane.org" = servo;
    "git.uninsane.org" = servo;
  };
in {
  # map hostname -> something suitable for known_keys
  hosts = builtins.mapAttrs (machine: keys: withHost machine keys.host) keys;
  # map hostname -> something suitable for authorized_keys to allow access to colin@<hostname>
  users = builtins.mapAttrs (machine: keys: withUser "colin@${machine}" keys.users.colin) keys;
}

