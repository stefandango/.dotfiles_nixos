{ lib, pkgs, vars, ... }:

let
	colors = import ../theme/colors.nix;
in
{
	programs.nixvim = {
		enable = true;
		viAlias = true;
		vimAlias = true;
		defaultEditor = true;
		colorschemes.rose-pine = {
			enable = true;
			package = pkgs.vimPlugins.rose-pine;
			transparentBackground = true;
		};
		autoCmd = [
		{
			event = "VimEnter";
			command = "set nofoldenable";
			desc = "Unfold All";
		}
		{
			event = "BufWrite";
			command = "%s/\\s\\+$//e";
			desc = "Remove Whitespaces";
		}
		];
		options = {
			number = true;
			relativenumber = true;
			hidden = true;
			foldlevel = 99;
			tabstop = 4;
			softtabstop = 4;
			shiftwidth = 4;
			expandtab = true;
			autoindent = true;
			wrap = false;
			scrolloff = 8;
			sidescroll = 40;
			completeopt = ["menu" "menuone" "noselect"];
			pumheight = 15;
			swapfile = false;
			timeoutlen = 2500;
			conceallevel = 3;
			undofile = true;
			ignorecase = true;
			smartcase = true;
		};
		extraConfigLua = ''
			vim.opt.smartcase = true
			vim.opt.ignorecase = true
			vim.opt.hlsearch = false
			vim.opt.incsearch = true
			vim.opt.mouse = 'a'
			vim.opt.signcolumn = "yes"
			vim.opt.isfname:append("@-@")

			vim.opt.colorcolumn = "120"
			vim.opt.cmdheight = 0
			vim.opt.shortmess:append('I')

		'';
		clipboard = {
			register = "unnamedplus";
			providers.wl-copy.enable = true;
		};
		
		globals = {
			mapleader = " ";
			maplocalleader = " ";
		};
	};
}
