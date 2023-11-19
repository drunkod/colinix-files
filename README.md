## What's Here

this is the top-level repo from which i configure/deploy all my NixOS machines:
- desktop
- laptop
- server
- mobile phone (Pinephone)

everything outside of <./hosts/> and <./secrets/> is intended for export, to be importable for use by 3rd parties.
the only hard dependency for my exported pkgs/modules should be [nixpkgs][nixpkgs].
building <./hosts/> will require [sops][sops].

you might specifically be interested in these files (elaborated further in #key-points-of-interest):
- [`sxmo-utils`](./pkgs/additional/sxmo-utils/default.nix)
  - [example SXMO deployment](./hosts/modules/gui/sxmo/default.nix)
- [my implementation of impermanence](./modules/persist/default.nix)
- my way of deploying dotfiles/configuring programs per-user:
  - <./modules/fs/default.nix>
  - <./modules/programs.nix>
  - <./modules/users.nix>

[nixpkgs]: https://github.com/NixOS/nixpkgs
[sops]: https://github.com/Mic92/sops-nix
[uninsane-org]: https://uninsane.org

## Using This Repo In Your Own Config

this should be a pretty "standard" flake. just reference it, and import either
- `nixosModules.sane` (for the modules)
- `overlays.pkgs` (for the packages)

or follow the instructions [here][NUR] to use it via the Nix User Repositories.

[NUR]: https://nur.nix-community.org/

## Layout
- `doc/`
    - instructions for tasks i find myself doing semi-occasionally in this repo.
- `hosts/`
    - the bulk of config which isn't factored with external use in mind.
    - that is, if you were to add this repo to a flake.nix for your own use,
      you won't likely be depending on anything in this directory.
- `integrations/`
    - code intended for consumption by external tools (e.g. the Nix User Repos)
- `modules/`
    - config which is gated behind `enable` flags, in similar style to nixpkgs'
      `nixos/` directory.
    - if you depend on this repo, it's most likely for something in this directory.
- `nixpatches/`
    - literally, diffs i apply atop upstream nixpkgs before performing further eval.
- `overlays/`
    - exposed via the `overlays` output in `flake.nix`.
    - predominantly a list of `callPackage` directives.
- `pkgs/`
    - derivations for things not yet packaged in nixpkgs.
    - derivations for things from nixpkgs which i need to `override` for some reason.
    - inline code for wholly custom packages (e.g. `pkgs/additional/sane-scripts/` for CLI tools
      that are highly specific to my setup).
- `scripts/`
    - scripts which aren't reachable on a deployed system, but may aid manual deployments
- `secrets/`
    - encrypted keys, API tokens, anything which one or more of my machines needs
      read access to but shouldn't be world-readable.
    - not much to see here
- `templates/`
    - exposed via the `templates` output in `flake.nix`.
    - used to instantiate short-lived environments.
    - used to auto-fill the boiler-plate portions of new packages.


## Key Points of Interest

i.e. you might find value in using these in your own config:

- `modules/fs/`
    - use this to statically define leafs and nodes anywhere in the filesystem,
      not just inside `/nix/store`.
    - e.g. specify that `/var/www` should be:
        - owned by a specific user/group
        - set to a specific mode
        - symlinked to some other path
        - populated with some statically-defined data
        - populated according to some script
        - created as a dependency of some service (e.g. `nginx`)
    - values defined here are applied neither at evaluation time _nor_ at activation time.
        - rather, they become systemd services.
        - systemd manages dependencies
        - e.g. link `/var/www -> /mnt/my-drive/www` only _after_ `/mnt/my-drive/www` appears)
    - this is akin to using [Home Manager's][home-manager] file API -- the part which lets you
      statically define `~/.config` files -- just with a different philosophy.
- `modules/persist/`
    - my alternative to the Impermanence module.
    - this builds atop `modules/fs/` to achieve things stock impermanence can't:
        - persist things to encrypted storage which is unlocked at login time (pam_mount).
        - "persist" cache directories -- to free up RAM -- but auto-wipe them on mount
          and encrypt them to ephemeral keys so they're unreadable post shutdown/unmount.
- `modules/programs.nix`
    - like nixpkgs' `programs` options, but allows both system-wide or per-user deployment.
    - allows `fs` and `persist` config values to be gated behind program deployment:
        - e.g. `/home/<user>/.mozilla/firefox` is persisted only for users who
          `sane.programs.firefox.enableFor.user."<user>" = true;`
- `modules/users.nix`
    - convenience layer atop the above modules so that you can just write
      `fs.".config/git"` instead of `fs."/home/colin/.config/git"`

some things in here could easily find broader use. if you would find benefit in
them being factored out of my config, message me and we could work to make that happen.

[home-manager]: https://github.com/nix-community/home-manager

## Mirrors

this repo exists in a few known locations:
- primary: <https://git.uninsane.org/colin/nix-files>
- mirror: <https://github.com/nix-community/nur-combined/tree/master/repos/colinsane>

## Contact

if you want to contact me for questions, or collaborate to split something useful into a shared repo, etc,
you can reach me via any method listed [here](https://uninsane.org/about).
patches, for this repo or any other i host, will be warmly welcomed in any manner you see fit:
`git send-email`, DM'ing the patch over Matrix/Lemmy/ActivityPub/etc, even a literal PR where you
link me to your own clone.
