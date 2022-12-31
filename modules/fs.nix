{ config, lib, pkgs, utils, ... }:
with lib;
let
  cfg = config.sane.fs;

  serviceNameFor = path: "ensure-${utils.escapeSystemdPath path}";

  # sane.fs."<path>" top-level options
  fsEntry = types.submodule ({ name, ...}: let
    parent = parentDir name;
    has-parent = hasParent name;
    parent-cfg = if has-parent then cfg."${parent}" else {};
  in {
    options = {
      dir = mkOption {
        type = mkDirEntryType (parent-cfg.dir or {
          user = "root";
          group = "root";
          mode = "0755";
        });
      };
      depends = mkOption {
        type = types.listOf types.str;
        description = "list of systemd units needed to be run before this service";
        default = [];
      };
      unit = mkOption {
        type = types.str;
        description = "name of the systemd unit which ensures this entry";
      };
    };
    config = {
      # we put this here instead of as a `default` to ensure that users who specify additional
      # dependencies still get a dep on the parent (unless they assign with `mkForce`).
      depends = if has-parent then [ parent-cfg.unit ] else [];
      # this option for the benefit of being read by users (for now).
      # making it read-only simplifies our impl.
      unit = (serviceNameFor name) + ".service";
    };
  });
  # sane.fs."<path>".dir sub-options
  mkDirEntryType = defaults: types.submodule {
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
    config = lib.mkDefault defaults;
  };

  # given a fsEntry definition, output the `config` attrs it generates.
  mkFsConfig = path: opt: {
    systemd.services."${serviceNameFor path}" = {
      description = "prepare ${path}";
      script = ensure-dir-script;
      scriptArgs = "${path} ${opt.dir.user} ${opt.dir.group} ${opt.dir.mode}";
      serviceConfig.Type = "oneshot";
      after = opt.depends;
      wants = opt.depends;
      # prevent systemd making this unit implicitly dependent on sysinit.target.
      # see: <https://www.freedesktop.org/software/systemd/man/systemd.special.html>
      unitConfig.DefaultDependencies = "no";
    };
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

  config = let
    cfgs = builtins.attrValues (builtins.mapAttrs mkFsConfig cfg);
  in {
    # we can't lib.mkMerge at the top-level, so do it per-attribute
    systemd = lib.mkMerge (catAttrs "systemd" cfgs);
  };
}
