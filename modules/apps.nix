{ config, lib, pkgs, unstable, vars, ...}:
{
    environment.systemPackages = with pkgs; [
        obsidian
        vscode-fhs
    ] ++
    (with unstable; [
        jetbrains.rider
    ]);
    nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
    ];
    programs.steam.enable = true;

}
