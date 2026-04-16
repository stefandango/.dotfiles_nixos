#
#  Git Configuration - Home Manager Module
#
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    meld
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "OneHalfDark";
    };
  };

  programs.git = {
    enable = true;
    signing.format = null;
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
        defaultBranch = "main";
      };
      credential = {
        helper = "cache";
      };
    };
  };
}
