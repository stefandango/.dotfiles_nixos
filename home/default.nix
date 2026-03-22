{ config, lib, pkgs, vars, ... }:

{
  # Home Manager configuration that works on both platforms
  home = {
    username = vars.user;
    homeDirectory = if pkgs.stdenv.isDarwin
      then "/Users/${vars.user}"
      else "/home/${vars.user}";
    stateVersion = "23.11";
  };

  # Enable XDG base directories (cross-platform)
  xdg.enable = true;

  # Redirect apps to XDG paths
  home.sessionVariables = {
    # History files
    LESSHISTFILE = "${config.xdg.stateHome}/lesshst";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";

    # Development tools
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/mod";
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    NUGET_PACKAGES = "${config.xdg.cacheHome}/NuGetPackages";

    # npm
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
  };

  # Import shared home modules
  imports = [
    ../modules/shared/default.nix
    ../theme/theming.nix
  ];

  # Cross-platform home packages
  home.packages = with pkgs; [
    # Development tools
    gopls         # Go language server

    # Modern CLI tools
    zoxide        # Smarter cd command (learns your habits)
    delta         # Beautiful git diffs

    # System utilities
    curl
    btop
    gum           # Glamorous shell scripts
  ];

  # Enable home-manager
  programs.home-manager.enable = true;
}