{ config, lib, pkgs, unstable, vars, ...}:
{
    environment.systemPackages = with pkgs; [
        obsidian
        jetbrains.rider
        vscode-fhs
    ];
    nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
    ];
    programs.steam.enable = true;

}
