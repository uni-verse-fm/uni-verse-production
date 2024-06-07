{
  description = "Uni-verse module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    uni-verse-frontend = {
      url = "github:uni-verse-fm/uni-verse-frontend";
      flake = false;
    };

    uni-verse-backend = {
      url = "github:uni-verse-fm/uni-verse-api";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: {
    nixosModules = {
      default = {
        imports = [
          ./nix/module.nix
          ./nix/options.nix
        ];
      };
    };
  };
}
