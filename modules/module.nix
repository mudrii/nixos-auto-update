moduleConfig:
{ lib, pkgs, config, ... }:

with lib;

{
  options.services.nixos-auto-update = with types;{
    enable = mkEnableOption "Auto update NixOS weekly";
    gitPackage = mkOption {
      type = package;
      default = pkgs.git;
    };
  };

  config =
    let
      cfg = config.services.nixos-auto-update;
      gitPath = "${cfg.gitPackage}/bin/git";
      mkStartScript = name: pkgs.writeShellScript "${name}.sh" ''
        set -euo pipefail
        PATH=${makeBinPath (with pkgs; [ git ])}
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix"
        cd /etc/nixos/
        ${gitPath} pull origin master
        ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --flake '/etc/nixos/#nixtst' --impure
      '';
    in
    mkIf cfg.enable (
      moduleConfig rec {
        name = "nixos-auto-update";
        description = "Auto update NixOS weekly";
        serviceConfig = {
          ExecStart = "${mkStartScript name}";
        };
        timerConfig = {
          OnBootSec = "5m"; # first run 5min after boot up
          #OnUnitActiveSec = "1w"; # run weekly
        };
      }
    );
}
