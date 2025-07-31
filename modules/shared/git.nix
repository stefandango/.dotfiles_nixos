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
    userEmail = "5796872+stefandango@users.noreply.github.com";
    userName = "Stefan";
    aliases = {
      graph = "log --all --graph --decorate --oneline";
    };
    extraConfig = {
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
      };
      merge = {
        ff = false;
        tool = "meld";
      };
      mergetool = {
        cmd = "meld $BASE $LOCAL $REMOTE $MERGED";
        keepBackup = false;
      };
      credential = {
        helper = "cache";
      };
    };
  };
}
