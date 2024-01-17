{ config, lib, pkgs, unstable, vars, ...}:
{
   environment.systemPackages = with pkgs; [
	obsidian
	jetbrains.rider
    ];
  nixpkgs.config.permittedInsecurePackages = [
                "electron-25.9.0"
              ];
}
