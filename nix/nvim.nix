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
            hlsearch = false;
            incsearch = true;
            mouse = "a";
            signcolumn = "yes";
            colorcolumn = "120";
            cmdheight = 0;

		};
		extraConfigLua = ''
			vim.opt.isfname:append("@-@")
			vim.opt.shortmess:append('I')

            require('neoscroll').setup()

		'';
		clipboard = {
			register = "unnamedplus";
			providers.wl-copy.enable = true;
		};

		globals = {
			mapleader = " ";
			maplocalleader = " ";
		};

        plugins = {
            nvim-tree = {
                enable = true;
                sortBy = "case_sensitive";
                view = {
                    relativenumber = true;
                    number = true;
                    float = {
                        enable = true;
                        openWinConfig = {
                            border = "rounded";
                            relative = "editor";
                        };
                    };

                };
            };
        };

        extraPlugins = with pkgs.vimPlugins; [
            neoscroll-nvim
        ];
	};
}
