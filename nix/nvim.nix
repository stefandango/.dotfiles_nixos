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
		#colorschemes.rose-pine = {
		#	enable = true;
		#	package = pkgs.vimPlugins.rose-pine;
		#	transparentBackground = true;
		#};
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
		clipboard = {
			register = "unnamedplus";
			providers.wl-copy.enable = true;
		};

		globals = {
			mapleader = " ";
			maplocalleader = " ";
		};

        keymaps = [
        {
            key = "<leader>.";
            action = "<CMD>NvimTreeToggle<CR>";
            options.desc = "Toggle NeoTree";
        }
        ];

        plugins = {
        };

        extraPlugins = with pkgs.vimPlugins; [
            neoscroll-nvim
            nvim-tree-lua
            onedark-nvim
        ];

		extraConfigLua = ''
			vim.opt.isfname:append("@-@")
			vim.opt.shortmess:append('I')

            require('neoscroll').setup()

            local HEIGHT_RATIO = 0.8  -- You can change this
            local WIDTH_RATIO = 0.5   -- You can change this too

            require("nvim-tree").setup({
                    sort_by = "case_sensitive",
                    view = {
                    relativenumber = true,
                    number = true,
                    side = "right",
                    width = 100,
                    float = {
                    enable = true,
                    open_win_config = function()
                    local screen_w = vim.opt.columns:get()
                    local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                    local window_w = screen_w * WIDTH_RATIO
                    local window_h = screen_h * HEIGHT_RATIO
                    local window_w_int = math.floor(window_w)
                    local window_h_int = math.floor(window_h)
                    local center_x = (screen_w - window_w) / 2
                    local center_y = ((vim.opt.lines:get() - window_h) / 2)
                    - vim.opt.cmdheight:get()
                    return {
                        border = 'rounded',
                        relative = 'editor',
                        row = center_y,
                        col = center_x,
                        width = window_w_int,
                        height = window_h_int,
                    }
                    end,
                    },
                    },
                    renderer = {
                        group_empty = true,
                        highlight_git = true
                    },
                    filters = {
                        dotfiles = false,
                    },
            })

        require('onedark').setup {
            style = 'warmer',
                  transparent = true,
                  -- Lualine options --
                      lualine = {
                          transparent = true, -- lualine center bar transparency
                      },
        }
        require('onedark').load()

		'';

	};
}
