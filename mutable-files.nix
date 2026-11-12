# This module extends home.file, xdg.configFile and xdg.dataFile with the `mutable` option.
{ config, lib, ... }:
let
  fileOptionAttrPaths = [
    [
      "home"
      "file"
    ]
    [
      "xdg"
      "configFile"
    ]
    [
      "xdg"
      "dataFile"
    ]
  ];

  allFiles = builtins.concatLists (
    map (attrPath: builtins.attrValues (lib.getAttrFromPath attrPath config)) fileOptionAttrPaths
  );
  mutableFiles = builtins.filter (file: file.mutable or false) allFiles;
in
{
  options =
    let
      mergeAttrsList = builtins.foldl' (lib.recursiveUpdate) { };
      fileAttrsType = lib.types.attrsOf (
        lib.types.submodule {
          options.mutable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to copy the file without the read-only attribute instead of
              symlinking. If you set this to `true`, you must also set `force` to
              `true`. Mutable files are not removed when you remove them from your
              configuration.

              This option is useful for programs that don't have a very good
              support for read-only configurations.
            '';
          };
        }
      );
    in
    mergeAttrsList (
      map (
        attrPath: lib.setAttrByPath attrPath (lib.mkOption { type = fileAttrsType; })
      ) fileOptionAttrPaths
    );

  config.home.activation.mutableFileGeneration =
    let
      toCommand =
        file:
        let
          source = lib.escapeShellArg file.source;
          target = lib.escapeShellArg file.target;
        in
        ''
          $VERBOSE_ECHO "${source} -> ${target}"
          $DRY_RUN_CMD cp --remove-destination --no-preserve=mode ${source} ${target}
        '';
      command = ''
        echo "Copying mutable home files for $HOME"
      ''
      + lib.concatLines (map toCommand mutableFiles);
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] command;
  config.xdg.configFile."hm-mutable-files/files".text = lib.concatLines (
    lib.unique (map (f: f.target) mutableFiles)
  );
}
