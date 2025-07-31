{ config, lib, pkgs, vars, ...}:
{
    environment.systemPackages = with pkgs; [
        obsidian
        #insomnia
        spotify
        #beekeeper-studio
        #dbeaver-bin
        azuredatastudio
        github-copilot-intellij-agent
        vscode-fhs
        jetbrains.rider
    ];
    
    nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
    ];
}
