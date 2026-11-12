# hm-mutable-files

[![AI:R READ](https://img.shields.io/badge/AI-READ-grey?style=flat&logoSize=auto&labelColor=13171f)](https://0rwx.com)

A Home Manager module that makes selected `home.file`, `xdg.configFile` and `xdg.dataFile` entries
*mutable*. Normally these are symlinked into the home directory, pointing at read-only Nix store
paths. A mutable file is copied instead of symlinked, so programs can modify it in place.

This is useful for programs that do not cope well with read-only configurations, or when you want to
track changes a program makes to its own config files.

## Usage

Add this flake as an input:

```nix
{
  inputs = {
    hm-mutable-files = {
      url = "github:komar007/hm-mutable-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Import the module and set `mutable = true` on the files you want writable:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.hm-mutable-files.homeManagerModules.mutable-files
  ];

  home.file.".codex/config.toml" = {
    source = ./codex-config.toml;
    mutable = true;
  };

  xdg.configFile."git/config" = {
    source = ./git-config;
    mutable = true;
  };
}
```

On activation the file is copied to its target with write permission, replacing the symlink that
Home Manager would otherwise create.

> [!NOTE]
> When updating with `home-manager switch`, mutable files that did not diverge generate a warning:
>
> ```
> Existing file '…' is in the way of '/nix/store/…', will be skipped since they are the same
> ```
>
> This is expected behavior.
>
> Mutable files that did diverge prevent activation of a new generation, unless `force` or `-b` or
> `-B` is used (see below), which conveniently protects you from losing changes introduced while you
> weren't watching.

### Divergence

When a mutable file diverges from the managed source (for example, a program edits it), the next
`home-manager switch` fails during activation.

This prevents the mutation from being overwritten, as Home Manager treats the file as not its own.
Either update your configuration to match the modified file exactly (see note above), or back it up
with `home-manager switch -b` (or `-B`) for later inspection.

> [!TIP]
> For the cases where external mutations are disposable, use
> [`home.file.<name>.force`](https://home-manager-options.extranix.com/?query=home.file.%3Cname%3E.force)
> /
> [`xdg.configFile.<name>.force`](https://home-manager-options.extranix.com/?query=xdg.configFile.%3Cname%3E.force)
> /
> [`xdg.dataFile.<name>.force`](https://home-manager-options.extranix.com/?query=xdg.dataFile.%3Cname%3E.force).
> Using `force` in combination with `mutate` still makes sense for software that fails or crashes
> when trying to write to its config files when they are read-only.

### `hm-mutable-diff`

The module installs a `hm-mutable-diff` tool (unless disabled, [see below](#options)) that diffs
live files against a Home Manager generation:

```sh
hm-mutable-diff                          # changes since the current generation
hm-mutable-diff --base-flake [flake-uri] # changes vs. a generation to be activated
```

If `flake-uri` is omitted, the Home Manager default flake is used.

Before switching Home Manager configurations, or also occasionally, use `hm-mutable-diff` to see how
mutable files have diverged from the current generation. Based on its output you may now
re-introduce these changes to your configuration.

> [!TIP]
> `--base-flake` becomes useful when reconciling changes, as re-introduction of external mutations
> via home-manager's options may produce logically-equivalent, but not exactly equal changes in the
> file. This option will show you how diverged files differ from a Home Manager configuration you
> are working on, without applying it.
>
> When you decide your version is good enough, switch configurations with
> `home-manager switch -b <backup_ext>`.

## Options

| Option                           | Type    | Default | Description                          |
| -------------------------------- | ------- | ------- | ------------------------------------ |
| `home.file.<name>.mutable`       | boolean | `false` | Copy the file instead of symlinking. |
| `xdg.configFile.<name>.mutable`  | boolean | `false` | Copy the file instead of symlinking. |
| `xdg.dataFile.<name>.mutable`    | boolean | `false` | Copy the file instead of symlinking. |
| `mutableFiles.enableMutableDiff` | boolean | `true`  | Install the `hm-mutable-diff` tool.  |

### Known limitations

Mutable files are not removed when you drop them from your configuration.
