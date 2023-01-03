{ config, lib, pkgs, utils, ... }:
with lib;
let
  cfg = config.sane.fs;

  mountNameFor = path: "${utils.escapeSystemdPath path}.mount";
  serviceNameFor = path: "ensure-${utils.escapeSystemdPath path}";

  # sane.fs."<path>" top-level options
  fsEntry = types.submodule ({ name, config, ...}: let
    parent = parentDir name;
    has-parent = hasParent name;
    parent-cfg = if has-parent then cfg."${parent}" else {};
    parent-dir = parent-cfg.dir or {};
    parent-acl = parent-dir.acl or {};
  in {
    options = {
      dir = mkOption {
        type = dirEntry;
      };
      mount = mkOption {
        type = types.nullOr (mountEntryFor name);
        default = null;
      };
      unit = mkOption {
        type = types.str;
        description = "name of the systemd unit which ensures this entry";
      };
    };
    config = {
      dir.acl.user = lib.mkDefault (parent-acl.user or "root");
      dir.acl.group = lib.mkDefault (parent-acl.group or "root");
      dir.acl.mode = lib.mkDefault (parent-acl.mode or "0755");
      # we put this here instead of as a `default` to ensure that users who specify additional
      # dependencies still get a dep on the parent (unless they assign with `mkForce`).
      dir.depends = if has-parent then [ parent-cfg.unit ] else [];
      # if defaulted, this module is responsible for creating the directory
      dir.unit = lib.mkDefault ((serviceNameFor name) + ".service");

      # if defaulted, this module is responsible for finalizing the entry.
      # the user could override this if, say, they finalize some aspect of the entry
      # with a custom service.
      unit = lib.mkDefault (if config.mount != null then
        config.mount.unit
      else config.dir.unit);
    };
  });

  acl = types.submodule {
    options = {
      user = mkOption {
        type = types.str;  # TODO: use uid?
      };
      group = mkOption {
        type = types.str;
      };
      mode = mkOption {
        type = types.str;
      };
    };
  };

  # sane.fs."<path>".dir sub-options
  dirEntry = types.submodule {
    options = {
      acl = mkOption {
        type = acl;
      };
      depends = mkOption {
        type = types.listOf types.str;
        description = "list of systemd units needed to be run before this directory can be made";
        default = [];
      };
      reverseDepends = mkOption {
        type = types.listOf types.str;
        description = "list of systemd units which should be made to depend on this unit (controls `wantedBy` and `before`)";
        default = [];
      };
      unit = mkOption {
        type = types.str;
        description = "name of the systemd unit which ensures this directory";
      };
    };
  };

  # sane.fs."<path>".mount sub-options
  mountEntryFor = path: types.submodule {
    options = {
      bind = mkOption {
        type = types.nullOr types.str;
        description = "fs path to bind-mount from";
        default = null;
      };
      extraOptions = mkOption {
        type = types.listOf types.str;
        description = "extra fstab options for this mount";
        default = [];
      };
      unit = mkOption {
        type = types.str;
        description = "name of the systemd unit which mounts this path";
        default = mountNameFor path;
      };
    };
  };

  # given a fsEntry definition, output the `config` attrs it generates.
  mkDirConfig = path: opt: {
    systemd.services."${serviceNameFor path}" = {
      description = "prepare ${path}";
      serviceConfig.Type = "oneshot";

      script = ensure-dir-script;
      scriptArgs = "${path} ${opt.dir.acl.user} ${opt.dir.acl.group} ${opt.dir.acl.mode}";

      after = opt.dir.depends;
      wants = opt.dir.depends;
      # prevent systemd making this unit implicitly dependent on sysinit.target.
      # see: <https://www.freedesktop.org/software/systemd/man/systemd.special.html>
      unitConfig.DefaultDependencies = "no";

      wantedBy = opt.dir.reverseDepends;
      before = opt.dir.reverseDepends;
    };
  };

  mkMountConfig = path: opt: (let
    underlying = cfg."${opt.mount.bind}";
  in {
    fileSystems."${path}" = lib.mkIf (opt.mount.bind != null) {
      device = opt.mount.bind;
      options = [
        "bind"
        # x-systemd options documented here:
        # - <https://www.freedesktop.org/software/systemd/man/systemd.mount.html>
        # we can't mount this until after the underlying path is prepared.
        # if the underlying path disappears, this mount will be stopped.
        "x-systemd.requires=${underlying.dir.unit}"
        # the mount depends on its target directory being prepared
        "x-systemd.requires=${opt.dir.unit}"
      ] ++ opt.mount.extraOptions;
      noCheck = true;
    };
  });

  mkFsConfig = path: opt: mergeTopLevel [
    (mkDirConfig path opt)
    (lib.mkIf (opt.mount != null) (mkMountConfig path opt))
  ];

  # act as `config = lib.mkMerge [ a b ]` but in a way which avoids infinite recursion,
  # by extracting only specific options which are known to not be options in this module.
  mergeTopLevel = items: let
    # if one of the items is `lib.mkIf cond attrs`, we won't be able to index it until
    # after we "push down" the mkIf to each attr.
    indexable = lib.pushDownProperties (lib.mkMerge items);
    # transform (listOf attrs) to (attrsOf list) by grouping each toplevel attr across lists.
    top = lib.zipAttrsWith (name: lib.mkMerge) indexable;
    # extract known-good top-level items in a way which errors if a module tries to define something extra.
    extract = { fileSystems ? {}, systemd ? {} }@attrs: attrs;
  in {
    inherit (extract top) fileSystems systemd;
  };

  # systemd/shell script used to create and set perms for a specific dir
  ensure-dir-script = ''
    path="$1"
    user="$2"
    group="$3"
    mode="$4"

    if ! test -d "$path"
    then
      # if the directory *doesn't* exist, try creating it
      # if we fail to create it, ensure we raced with something else and that it's actually a directory
      mkdir "$path" || test -d "$path"
    fi
    chmod "$mode" "$path"
    chown "$user:$group" "$path"
  '';

  # split the string path into a list of string components.
  # root directory "/" becomes the empty list [].
  # implicitly performs normalization so that:
  # splitPath "a//b/" => ["a" "b"]
  # splitPath "/a/b" =>  ["a" "b"]
  splitPath = str: builtins.filter (seg: (builtins.isString seg) && seg != "" ) (builtins.split "/" str);
  # return a string path, with leading slash but no trailing slash
  joinPathAbs = comps: "/" + (builtins.concatStringsSep "/" comps);
  concatPaths = paths: joinPathAbs (builtins.concatLists (builtins.map (p: splitPath p) paths));
  # normalize the given path
  normPath = str: joinPathAbs (splitPath str);
  # return the parent directory. doesn't care about leading/trailing slashes.
  # the parent of "/" is "/".
  parentDir = str: normPath (builtins.dirOf (normPath str));
  hasParent = str: (parentDir str) != (normPath str);

  # return all ancestors of this path.
  # e.g. ancestorsOf "/foo/bar/baz" => [ "/" "/foo" "/foo/bar" ]
  ancestorsOf = path: if hasParent path then
    ancestorsOf (parentDir path) ++ [ (parentDir path) ]
  else
    [ ]
  ;

  # attrsOf fsEntry type which for every entry ensures that all ancestor entries are created.
  # we do this with a custom type to ensure that users can access `config.sane.fs."/parent/path"`
  # when inferred.
  fsTree = let
    baseType = types.attrsOf fsEntry;
    # merge is called once, with all collected `sane.fs` definitions passed and we coalesce those
    # into a single value `x` as if the user had wrote simply `sane.fs = x` in a single location.
    # so option defaulting and such happens *after* `merge` is called.
    merge = loc: defs: let
      # loc is the location of the option holding this type, e.g. ["sane" "fs"].
      # each def is an { value = attrsOf fsEntry instance; file = "..."; }
      pathsForDef = def: attrNames def.value;
      origPaths = concatLists (builtins.map pathsForDef defs);
      extraPaths = concatLists (builtins.map ancestorsOf origPaths);
      extraDefs = builtins.map (p: {
        file = ./.;
        value = {
          "${p}".dir = {};
        };
      }) extraPaths;
    in
      baseType.merge loc (defs ++ extraDefs);
  in
    lib.mkOptionType {
      inherit merge;
      name = "fsTree";
      description = "attrset representation of a file-system tree";
      # ensure that every path is in canonical form, else we might get duplicates and subtle errors
      check = tree: builtins.all (p: p == normPath p) (builtins.attrNames tree);
    };

in {
  options = {
    sane.fs = mkOption {
      # type = types.attrsOf fsEntry;
      type = fsTree;
      default = {};
    };
  };

  config = mergeTopLevel (lib.mapAttrsToList mkFsConfig cfg);
}
