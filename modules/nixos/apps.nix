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
        zed-editor
        discord
        hyperhdr
        # herdr's desktop app. Its backend is nixpkgs' separate herdr-core
        # package, not the herdr CLI in the host's systemPackages; ships a
        # .desktop entry + icon.
        # macOS gets it as the herdr-app cask instead (hosts/macbook).
        herdr-desktop
    ];
}
