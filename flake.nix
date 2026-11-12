{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };
  outputs =
    { ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        systems = import inputs.systems;
        flake = rec {
          homeManagerModules.mutable-files = import ./mutable-files.nix;
          homeManagerModules.default = homeManagerModules.mutable-files;
        };
      }
    );
}
