{
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    services.universe = {
      enable = mkEnableOption "Uni-verse";

      envFile = mkOption {
        description = "Environment variables for Uni-verse";
        type = types.path;
        default = null;
      };
    };
  };
}
