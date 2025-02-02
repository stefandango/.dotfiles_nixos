{ lib, pkgs, vars, ... }:

#let
#colors = import ../theme/colors.nix;
#in
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
        {
            event = "FileType";
            pattern = [ "markdown" ];
            command = "setlocal scrolloff=30";
            desc = "Fixed cursor location on markdown (for preview)";
        }
        {
            event = "FileType";
            pattern = [ "markdown" ];
            command = "setlocal spell spelllang=en,da";
            desc = "Spell Checking";
        }
        ];
        opts = {
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
        # Overwites
        {
            mode = "n";
            key = "J";
            action = "mzJ`z";
            options.desc = "[OVERWRITE] - makes cursor stay en save position when using J in normal mode";
        }
        {
            mode = "n";
            key = "<C-d>";
            action = "<C-d>zz";
            options.desc = "C-d - keeps cursor in middle of screen if possible";
        }
        {
            mode = "n";
            key = "<C-u>";
            action = "<C-u>zz";
            options.desc = "C-u - keeps cursor in middle of screen if possible";
        }
        {
            mode = "n";
            key = "n";
            action = "nzzzv";
            options.desc = "Keeps cursor in middle when searching";
        }
        {
            mode = "n";
            key = "N";
            action = "Nzzzv";
            options.desc = "Keeps cursor in middle when searching";
        }
        {
            mode = "n";
            key = "Q";
            action = "<nop>";
            options.desc = "[OVERWRITE] Dont use...";
        }

        # Util
        {
            key = "<C-s>";
            action = "<CMD>w<CR>";
            options.desc = "Save";
        }
        {
            mode = "v";
            key = "K";
            action = ":m '<-2<CR>gv=gv";
            options.desc = "Move selected up";
        }
        {
            mode = "v";
            key = "J";
            action = ":m '>+1<CR>gv=gv";
            options.desc = "Move selected down";
        }
               {
            mode = "x";
            key = "<leader>p";
            action = "\"_dP";
            options.desc = "Keeps current buffer when pasting";
        }
        #{
        #    mode = "n";
        #    key = "<leader>y";
        #    action = "\"+y";
        #    options.desc = "Copy to system clipboard";
        #}
        #{
        #    mode = "v";
        #    key = "<leader>y";
        #    action = "\"+y";
        #    options.desc = "Copy to system clipboard";
        #}
        #{
        #    mode = "n";
        #    key = "<leader>Y";
        #    action = "\"+Y";
        #    options.desc = "Copy to system clipboard";
        #}

        {
            mode = "n";
            key = "<leader>d";
            action = "\"_d";
            options.desc = "Delete but keep the current clipboard";
        }
        {
            mode = "v";
            key = "<leader>d";
            action = "\"_d";
            options.desc = "Delete but keep the current clipboard";
        }
        #{
        #    mode = "n";
        #    key = "<C-f>";
        #    action = "<cmd>!~/Scripts/tmux-sessionizer<CR>";
        #    options.desc = "Open other tmux session.";
        #}
        {
            mode = "n";
            key = "<leader>x";
            action = "<cmd>!chmod +x %<CR>";
            options.desc = "set chmod+x for current file..";
        }

        # Window movement
        {
            key = "<leader><Left>";
            action = "<C-w>h";
            options.desc = "Select Window Left";
        }
        {
            key = "<leader>h";
            action = "<C-w>h";
            options.desc = "Select Window Left";
        }
        {
            key = "<leader><Right>";
            action = "<C-w>l";
            options.desc = "Select Window Right";
        }
        {
            key = "<leader>l";
            action = "<C-w>l";
            options.desc = "Select Window Right";
        }
        {
            key = "<leader><Down>";
            action = "<C-w>j";
            options.desc = "Select Window Below";
        }
        {
            key = "<leader>j";
            action = "<C-w>j";
            options.desc = "Select Window Below";
        }
        {
            key = "<leader><Up>";
            action = "<C-w>k";
            options.desc = "Select Window Above";
        }
        {
            key = "<leader>k";
            action = "<C-w>k";
            options.desc = "Select Window Above";
        }
        {
            key = "<leader>t";
            action = "<C-w>w";
            options.desc = "Cycle Between Windows";
        }


        # Buffers
        {
            key = "<leader>bb";
            action = "<CMD>BufferPick<CR>";
            options.desc = "View Open Buffer";
        }
        {
            key = "<leader>bc";
            action = "<CMD>BufferClose<CR>";
            options.desc = "View Open Buffer";
        }
        {
            key = "<leader>bn";
            action = "<CMD>:bnext<CR>";
            options.desc = "Next Buffer";
        }
        {
            key = "<leader>bp";
            action = "<CMD>:bprev<CR>";
            options.desc = "Previous Buffer";
        }


        # plugins ----------------------------------

        #Nerdtree
        {
            key = "<leader>.";
            action = "<CMD>NvimTreeToggle<CR>";
            options.desc = "Toggle NvimTree";
        }
        {
            key = "<leader>fe";
            action = "<CMD>NvimTreeToggle<CR>";
            options.desc = "Toggle NvimTree";
        }

#LSP
        {
            mode = "n";
            key = "gd";
            action = "<CMD>lua vim.lsp.buf.hover()<CR>";
            options.desc = "Hover documentation";
        }
        {
            mode = "n";
            key = "gD";
            action = "<CMD>lua vim.lsp.buf.definition()<CR>";
            options.desc = "Goto definition";
        }
        {
            mode = "n";
            key = "<leader>e";
            action = "<CMD>lua vim.diagnostic.open_float()<CR>";
            options.desc = "Diagnostic float";
        }
        {
            mode = "n";
            key = "<leader>ca";
            action = "<CMD>lua vim.lsp.buf.code_action()<CR>";
            options.desc = "Code action";
        }
        {
            mode = "v";
            key = "<leader>ca";
            action = "<CMD>lua vim.lsp.buf.code_action()<CR>";
            options.desc = "Code action";
        }
        {
            mode = "n";
            key = "<leader>rn";
            action = "<CMD>lua vim.lsp.buf.rename()<CR>";
            options.desc = "Rename";
        }

#Trouble
        {
            mode = "n";
            key = "<leader>gr";
            action = "<CMD>TroubleToggle lsp_references<CR>";
            options.desc = "Show all references";
        }
        {
            mode = "n";
            key = "<leader>q";
            action = "<CMD>Trouble diagnostics toggle<CR>";
            options.desc = "Show document diagnostic overview";
        }
      {
          mode = "n";
          key = "<leader>Q";
          action = "<CMD>Trouble diagnostics toggle filter.buf=0<CR>";
          options.desc = "Show workspace diagnostic overview";
      }
      # DEBUGGER (work in progress..)
      {
          mode = "n";
          key = "<F5>";
          action = "<CMD>lua require('dap').continue()<CR>";
          options.desc = "Debug: START";
      }
      {
          mode = "n";
          key = "<F10>";
          action = "<CMD>lua require('dap').step_over()<CR>";
          options.desc = "Debug: Step Over";
      }
      {
          mode = "n";
          key = "<leader><F10>";
          action = "<CMD>lua require('dap').step_back()<CR>";
          options.desc = "Debug: Step Back";
      }
      {
          mode = "n";
          key = "<F11>";
          action = "<CMD>lua require('dap').step_into()<CR>";
          options.desc = "Debug: Step Into";
      }
      {
          mode = "n";
          key = "<F12>";
          action = "<CMD>lua require('dap').step_out()<CR>";
          options.desc = "Debug: Step Out";
      }
      {
          mode = "n";
          key = "<leader>b";
          action = "<CMD>lua require('dap').toggle_breakpoint()<CR>";
          options.desc = "Debug: Toggle Breakpoint";
      }
      {
          mode = "n";
          key = "<leader>B";
          action = "<CMD>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>";
          options.desc = "Debug: Toggle Breakpoint";
      }
      {
          mode = "n";
          key = "<F4>";
          action = "<CMD>lua require('dap.ui.widgets').hover()<CR>";
          options.desc = "Debug: Hover variables";
      }
      {
          mode = "n";
          key = "<F3>";
          action = "<CMD>lua require('dap').terminate()<CR>";
          options.desc = "DEBUG: Terminate debug session";
      }
      # Neotest (STILL work in progress)
      {
        mode = "n";
        key = "<leader>tr";
        action = "<CMD>lua require('neotest').run.run()<CR>";
        options.desc = "DEBUG: Terminate debug session";
      }
      {
        mode = "n";
        key = "<leader>ts";
        action = "<CMD>lua require('neotest').summary.toggle()<CR>";
        options.desc = "DEBUG: Terminate debug session";
      }
      {
        mode = "n";
        key = "<leader>tf";
        action = "<CMD>lua require('neotest').run.run(vim.fn.expand('%'))<CR>";
        options.desc = "DEBUG: Terminate debug session";
      }
#GITHUB COPILOT Chat
      {
          mode = "n";
          key = "<leader>ct";
          action = "<CMD>CopilotChatToggle<CR>";
          options.desc = "CopilotChat - Toggle";
      }

      {
          mode = "n";
          key = "<leader>cq";
          action = "<CMD>lua require('CopilotChat').ask(vim.fn.input('Quick Chat: '), { selection = require('CopilotChat.select').buffer })<CR>";
          options.desc = "CopilotChat - Quick chat";
      }
      {
            mode = "v";
            key = "<leader>ch";
            action = "<CMD>lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').help_actions())<CR>";
            options.desc = "CopilotChat - Quick help";
      }
      {
            mode = "n";
            key = "<leader>ch";
            action = "<CMD>lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').help_actions())<CR>";
            options.desc = "CopilotChat - Quick help";
      }
      {
            mode = "v";
            key = "<leader>cp";
            action = "<CMD>lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions())<CR>";
            options.desc = "CopilotChat - Quick prompt actions";
      }
      {
            mode = "n";
            key = "<leader>cp";
            action = "<CMD>lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions())<CR>";
            options.desc = "CopilotChat - Quick prompt actions";
      }
      ];

        plugins = {
            treesitter = {
                enable = true;
                nixvimInjections = true;
                folding = false;
                nixGrammars = true;
                settings = {
                   incremental_selection.enable = true;
                   ensure_installed = "all";
                   indent.enable = true;
                };
            };
            web-devicons.enable = true;
            lualine.enable = true;
            barbar.enable = true;
            indent-blankline = {
                enable = true;
                settings.scope.enabled = true;
            };
            comment.enable = true;
            gitgutter.enable = true;
            fugitive.enable = true;
            nvim-autopairs.enable = true;
            markdown-preview.enable = true;
            rainbow-delimiters.enable = true;
            colorizer.enable = true;
            telescope = {
                enable = true;
                settings = {
                    pickers.find_files = {
                        hidden = true;
                    };
                };
                keymaps = {
                    "<leader>ff" = "find_files";
                    "<leader>fg" = "live_grep";
                    "<leader>fb" = "buffers";
                    "<leader>fh" = "keymaps";
                };
            };
            lsp = {
                enable = true;
                servers = {
                    html.enable = true;
                    cssls.enable = true;
                    ts_ls.enable = true;
                    pyright.enable = true;
                    #gopls.enable = true;
                    bashls.enable = true;
                    #csharp-ls.enable = true;
                    #dockerls.enable = true;
                    eslint.enable = true;
                    jsonls.enable = true;
                    #ltex.enable = true;
                    omnisharp = {
                        enable = true;
                        settings = {
                            enableRoslynAnalyzers = true;
                            organizeImportsOnFormat = true;
                            enableImportCompletion = true;
                        };
                    };
                    #rust-analyzer.enable = true;
                };
            };
            lspkind = {
                enable = true;
                cmp = {
                    enable = true;
                    menu = {
                        nvim_lsp = "[LSP]";
                        nvim_lua = "[api]";
                        path = "[path]";
                        luasnip = "[snip]";
                        buffer = "[buffer]";
                    };
                };
            };
            #lsp-lines.enable = true;
            luasnip.enable = true;
            cmp-nvim-lsp.enable = true;
            cmp_luasnip.enable = true;
            cmp = {
                enable = true;
                settings = {
                    snippet.expand = ''function(args) require('luasnip').lsp_expand(args.body) end'';
                };
                settings = {
                    mapping = {
                            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
                            "<C-f>" = "cmp.mapping.scroll_docs(4)";
                            "<C-Space>" = "cmp.mapping.complete()";
                            "<C-e>" = "cmp.mapping.close()";
                            "<Tab>" = "cmp.mapping.select_next_item()";
                            "<S-Tab>" = "cmp.mapping.select_prev_item()";
                            "<Down>" = "cmp.mapping.select_next_item()";
                            "<Up>" = "cmp.mapping.select_prev_item()";
                            "<C-j>" = "cmp.mapping.select_next_item()";
                            "<C-k>" = "cmp.mapping.select_prev_item()";
                            "<CR>" = "cmp.mapping.confirm({ select = true })";
                        };
                    sources = [
                    {name = "copilot";}
                    {name = "nvim_lsp";}
                    {name = "luasnip";}
                    {name = "path";}
                    {name = "buffer";}
                    {name = "nvim_lua";}
                    {name = "nvim_lsp_signature_help";}
                    ];
                };
            };
            trouble.enable = true;
            cmp-nvim-lsp-signature-help.enable = true;

            copilot-lua = {
                enable = true;
                settings = {
                    panel.enabled = false;
                    suggestion.enabled = false;
                };
            };
            copilot-cmp.enable = true;
        };

        extraPlugins = with pkgs.vimPlugins; [
            neoscroll-nvim
            nvim-tree-lua
            onedark-nvim
            nvim-dap
            nvim-dap-ui
            CopilotChat-nvim
            #plenary-nvim
            nvim-nio
            FixCursorHold-nvim
            neotest
            neotest-plenary
            neotest-dotnet
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

           require("CopilotChat").setup {
                debug = false, -- Enable debugging
                window = {
                    layout = 'vertical'
                },
            }

        require("neotest").setup({
                adapters = {
                require("neotest-dotnet")({
                        dap = {
                        -- Extra arguments for nvim-dap configuration
                        -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
                        args = {justMyCode = false },
                        -- Enter the name of your dap adapter, the default value is netcoredbg
                        -- adapter_name = "netcoredbg"
                        },
                        -- Let the test-discovery know about your custom attributes (otherwise tests will not be picked up)
                        -- Provide any additional "dotnet test" CLI commands here. These will be applied to ALL test runs performed via neotest. These need to be a table of strings, ideally with one key-value pair per item.
                        dotnet_additional_args = {
                        -- "--verbosity detailed"
                        },
                        -- Tell neotest-dotnet to use either solution (requires .sln file) or project (requires .csproj or .fsproj file) as project root
                        -- Note: If neovim is opened from the solution root, using the 'project' setting may sometimes find all nested projects, however,
                        --       to locate all test projects in the solution more reliably (if a .sln file is present) then 'solution' is better.
                            discovery_root = "solution" -- Default
                }),
                    require("neotest-plenary")
                },
                summary = {
        open = "botright split | vertical resize 80"
                }
        })

        -- DEBUGGER STUFF (VERY UNSTABLE STILL)

        local dap = require('dap')

        dap.adapters.coreclr = {
            type = 'executable',
            command = 'netcoredbg',
            args = {'--interpreter=vscode'}
        }

        dap.adapters.netcoredbg = {
            type = 'executable',
            command = 'netcoredbg',
            args = {'--interpreter=vscode'}
        }

        dap.configurations.cs = {
            {
                type = "coreclr",
                name = "launch - netcoredbg",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/', 'file')
                    end,
            },
        }


            local dapui = require("dapui")

            dapui.setup({
                    icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
                    mappings = {
                    expand = { "<CR>", "<2-LeftMouse>" },
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                    },
                    layouts = {
                            {
                                elements = {
                                    -- Elements can be strings or table with id and size keys.
                                    { id = "scopes", size = 0.25 },
                                    "breakpoints",
                                    "stacks",
                                    "watches",
                                },
                                size = 40, -- 40 columns
                                    position = "left",
                            },
                            {
                                elements = {
                                    "repl",
                                    "console",
                                },
                                size = 0.25, -- 25% of total lines
                                    position = "bottom",
                            },
                        },
                    controls = {
                        -- Requires Neovim nightly (or 0.8 when released)
                            enabled = true,
                        -- Display controls in this element
                            element = "repl",
                        icons = {
                            pause = "",
                            play = "",
                            step_into = "",
                            step_over = "",
                            step_out = "",
                            step_back = "",
                            run_last = "↻",
                            terminate = "󰿅",
                        },
                    },
                    floating = {
                        max_height = nil, -- These can be integers or a float between 0 and 1.
                            max_width = nil, -- Floats will be treated as percentage of your screen.
                            border = "single", -- Border style. Can be "single", "double" or "rounded"
                            mappings = {
                                close = { "q", "<Esc>" },
                            },
                    },
                    windows = { indent = 1 },
                    render = {
                        max_type_length = nil, -- Can be integer or nil.
                            max_value_lines = 100, -- Can be integer or nil.
                    }
            })


        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
            end

            local dap_breakpoint = {
                error = {
                    text = "🔴",
                    texthl = "LspDiagnosticsSignError",
                    linehl = "",
                    numhl = "",
                },
                rejected = {
                    text = "",
                    texthl = "LspDiagnosticsSignHint",
                    linehl = "",
                    numhl = "",
                },
                stopped = {
                    text = "👉",
                    texthl = "LspDiagnosticsSignInformation",
                    linehl = "DiagnosticUnderlineInfo",
                    numhl = "LspDiagnosticsSignInformation",
                },
            }

        vim.fn.sign_define("DapBreakpoint", dap_breakpoint.error)
            vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)
            vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
            '';
    };
}
