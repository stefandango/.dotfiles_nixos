{ config, lib, pkgs, vars, ... }:

{
  # Home Manager configuration that works on both platforms
  home = {
    username = vars.user;
    homeDirectory = if pkgs.stdenv.isDarwin
      then "/Users/${vars.user}"
      else "/home/${vars.user}";
    stateVersion = "23.11";

    # We intentionally run home-manager `master` with `nixos-unstable` (the correct
    # pairing). master labels itself a release ahead of nixpkgs (e.g. 26.11 vs 26.05),
    # which trips a benign version-mismatch warning. Silence it — it's expected skew.
    enableNixpkgsReleaseCheck = false;
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

  # Cross-platform scripts in ~/Scripts (NixOS-only scripts live in modules/nixos/scripts.nix)
  home.file."Scripts/llama-fetch" = {
    source = ../modules/scripts/llama-fetch;
    executable = true;
  };
  home.file."Scripts/llama" = {
    source = ../modules/scripts/llama;
    executable = true;
  };

  # Ensure the screenshot target dir exists (macOS silently falls back to
  # the Desktop if it's missing). Matches screencapture.location on macOS.
  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/Pictures/screenshots"
    '';
  };

  # MangoHud config (Linux only). Writes ~/.config/MangoHud/MangoHud.conf only —
  # enableSessionWide is intentionally left off, so MANGOHUD=1 is NOT exported.
  # Activate per-game in Steam with the `mangohud %command%` launch option.
  programs.mangohud = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    settings = {
      # FPS cap, matched to the 165Hz monitor. 0 = uncapped.
      # Toggle cycles 165 -> 60 -> uncapped.
      fps_limit = "165,60,0";
      toggle_fps_limit = "Shift_R+F1";

      cpu_stats = true;
      cpu_temp = true;
      gpu_stats = true;
      gpu_temp = true;
      ram = true;
      vram = true;
      frametime = true;
      frame_timing = true;
      fps = true;
      position = "top-left";
      font_size = 20;
      toggle_hud = "Shift_R+F12";
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}