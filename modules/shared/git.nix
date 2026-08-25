#
#  Git Configuration - Home Manager Module
#
{ config, lib, pkgs, inputs, ... }:

{
  # hunk: review-first terminal diff viewer (github:modem-dev/hunk).
  # Replaces delta (pager) and meld (difftool).
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  # enableGitIntegration sets core.pager = "hunk pager", so `git diff`
  # and `git show` open straight into hunk's review UI.
  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      theme = "github-dark-default";  # dark, matching the old delta OneHalfDark
      mode = "split";                 # side-by-side (was delta side-by-side = true)
      line_numbers = true;
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
      diff = {
        tool = "hunk";
        colorMoved = "default";    # Highlight moved code
      };
      difftool = {
        prompt = true;
        # `git difftool` opens each pair in hunk. Git substitutes $LOCAL/$REMOTE
        # with the temp files to compare (see `hunk diff before after`).
        hunk.cmd = ''hunk diff "$LOCAL" "$REMOTE"'';
      };
      # Syncing this repo between the desktop and the MacBook used to merge on
      # every pull, so a plain `git pull` with nothing to integrate still left a
      # "Merge remote-tracking branch 'origin/main'" bubble behind. Rebasing
      # replays the local commits on top instead, so a no-op sync is a no-op.
      pull = {
        rebase = true;
      };
      rebase = {
        # Without this a rebasing pull refuses to run on a dirty tree, which is
        # the normal state here (half-edited nix modules). Stash, rebase, pop.
        autoStash = true;
      };
      merge = {
        # Deliberate merges keep their merge commit: `wt done` folding a feature
        # branch back into main should stay visible as one. Pulls no longer
        # reach this setting now that they rebase.
        ff = false;
        # hunk is a read-only review viewer and cannot resolve 3-way merges,
        # so merges use git's built-in nvimdiff mergetool instead of meld.
        tool = "nvimdiff";
        conflictstyle = "diff3";   # Show original in merge conflicts
      };
      mergetool = {
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
