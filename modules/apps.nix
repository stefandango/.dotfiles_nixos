{ config, lib, pkgs, unstable, vars, ...}:
{
    environment.systemPackages = with pkgs; [
        obsidian
    ] ++
    (with unstable; [
        vscode-fhs
        jetbrains.rider
    ]);
    nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
    ];

}
