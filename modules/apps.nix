{ config, lib, pkgs, unstable, vars, ...}:
{
   environment.systemPackages = with pkgs; [
	dotnet-sdk_8
	obsidian
	jetbrains.rider
    ];
  nixpkgs.config.permittedInsecurePackages = [
                "electron-25.9.0"
              ];
}
