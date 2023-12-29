#
#  Git
#
{ config, lib, pkgs, home-manager, vars, ... }:
let
in
{
	home-manager.users.${vars.user} = {
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
					promt = true;
					cmd = "nvim -d \"$LOCAL\" \"REMOTE\"";
				};
				diff = {
					tool = "p4merge";
				};
				merge = {
					ff = false;
					tool = "p4merge";
				};
				mergetool = {
					cmd = "p4merge $BASE $LOCAL $REMOTE $MERGED";
					keepBackup = false;
				};
			};
		};
	};
}
