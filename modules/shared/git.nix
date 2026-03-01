#
#  Git Configuration - Home Manager Module
#
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    meld
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "5796872+stefandango@users.noreply.github.com";
        name = "Stefan";
      };
      alias = {
        graph = "log --all --graph --decorate --oneline";
      };
      core = {
        autocrlf = "input";
        editor = "nvim";
        pager = "delta";  # Use delta for beautiful diffs
      };
      interactive = {
        diffFilter = "delta --color-only";  # Use delta in interactive mode
      };
      delta = {
        navigate = true;           # Use n and N to move between diff sections
        light = false;             # Dark theme (set to true for light backgrounds)
        side-by-side = false;      # Line-by-line diff (set to true for side-by-side)
        line-numbers = true;       # Show line numbers
        syntax-theme = "OneHalfDark";  # Syntax highlighting theme
      };
      difftool = {
        prompt = true;
        cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
      };
      diff = {
        tool = "meld";
        colorMoved = "default";    # Highlight moved code
      };
      merge = {
        ff = false;
        tool = "meld";
        conflictstyle = "diff3";   # Show original in merge conflicts
      };
      mergetool = {
        cmd = "meld $BASE $LOCAL $REMOTE $MERGED";
        keepBackup = false;
      };
      init = {
        defaultBranch = "master";
      };
      credential = {
        helper = "cache";
      };
    };
  };
}
