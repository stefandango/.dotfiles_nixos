{ config, lib, pkgs, vars, ...}:
{
   environment.systemPackages = with pkgs; [
	obsidian
    ];
}
