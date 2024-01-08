{ config, lib, pkgs, unstable, vars, ...}:
{
   environment.systemPackages = with pkgs; [
	obsidian
    ];
  nixpkgs.config.permittedInsecurePackages = [
                "electron-25.9.0"
              ];
}
