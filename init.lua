-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.opt.wrap = false
vim.opt.shiftwidth = 4     -- Size of an indent (when you hit >)
vim.opt.tabstop = 4        -- Number of spaces that a <Tab> counts for
vim.opt.softtabstop = 4    -- Number of spaces that a <Tab> counts for while editing
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.clipboard = "unnamedplus"

require("lazy").setup({
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			-- Provides capabilities for LSP (autocompletion support)
			"saghen/blink.cmp",
		},
		config = function()
			-- This function runs when an LSP connects to a buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
					map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
					map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
				end,
			})

			vim.diagnostic.config({
				virtual_text = true,
				signs = false,
				update_in_insert = false,
				float = {
					source = "always",
					border = "single",
				},
			})

			vim.opt.number = true

			-- Standard LSP capabilities
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local servers = {
				lua_ls = {
					settings = {
						Lua = { completion = { callSnippet = "Replace" } },
					},
				},
                svelte = {
                  cmd = { "svelte-language-server", "--stdio" },
                },
                gopls = {
                    settings = {
                        gopls = {
                            semanticTokens = true,
                            analyses = {
                                unusedparams = true,
                                nilness = true,
                                unusedwrite = true,
                            },
                            staticcheck = true,
                            hints = {
                                assignVariableTypes = true,
                                compositeLiteralFields = true,
                                parameterNames = true,
                            },
                        },
                    },
                },
                clangd = {
                    cmd = { "clangd", "--background-index", "--clang-tidy" },
                },
				pyright = {},
				ts_ls = {
                filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
            },
			}
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, { "stylua" })
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	{
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			keymap = { preset = "default", ['<CR>'] = { 'accept', 'fallback' }, },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
		},
	},
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "latte",
                integrations = {
                    treesitter = true,
                    native_lsp = {
                        enabled = true,
                        underlines = {
                            errors = { "undercurl" },
                            hints = { "undercurl" },
                            warnings = { "undercurl" },
                            information = { "undercurl" },
                        },
                    },
                    semantic_tokens = true, -- Add this line
                },
            })

            vim.cmd.colorscheme("catppuccin")
        end,
    },
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      config = function()
        require('nvim-treesitter.config').setup({
          ensure_installed = {
            'bash', 'html', 'lua', 'svelte', 'typescript', 'javascript', 'css', 'go', 'gomod', 'c'
          },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
          indent = { enable = true },
        })
      end
    },
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {}
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp"
	},
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add          = { text = '┃' },
                change       = { text = '┃' },
                delete       = { text = '_' },
                topdelete    = { text = '‾' },
                changedelete = { text = '~' },
                untracked    = { text = '┆' },
            },
            on_attach = function(bufnr)
                local gitsigns = require('gitsigns')

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                map('n', ']c', function()
                    if vim.wo.diff then vim.cmd.feedkeys(']c', 'n') else gitsigns.nav_hunk('next') end
                end, { desc = 'Next Hunk' })

                map('n', '[c', function()
                    if vim.wo.diff then vim.cmd.feedkeys('[c', 'n') else gitsigns.nav_hunk('prev') end
                end, { desc = 'Prev Hunk' })

                map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Git [S]tage Hunk' })
                map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Git [R]eset Hunk' })
                map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Git [P]review Hunk' })
                map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end, { desc = 'Git [B]lame Line' })
            end
        }
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local cp = require("catppuccin.palettes").get_palette("latte")

            require('lualine').setup({
                options = {
                    theme = 'catppuccin',
                    -- These are the "Powerline" arrow shapes you liked
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { { 'mode', gui = 'bold' } },
                    lualine_b = {
                        { 'branch', icon = '', color = { fg = cp.mauve, bg = cp.mantle } },
                        { 'diff', colored = true, color = { bg = cp.mantle } },
                    },
                    lualine_c = {
                        {
                            'filename',
                            path = 1,
                            file_status = true,
                            color = { fg = cp.text, bg = cp.base }
                        },
                    },
                    lualine_x = {
                        {
                            'diagnostics',
                            symbols = { error = ' ', warn = ' ', info = ' ', hint = '󰌶 ' },
                            color = { bg = cp.base }
                        },
                        { 'filetype', color = { fg = cp.subtext1, bg = cp.base } }
                    },

                    -- Section Y/Z (Location)
                    lualine_y = { { 'progress', color = { bg = cp.mantle } } },
                    lualine_z = { { 'location', gui = 'bold' } },
                },
            })
        end
    },
})

vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = { "*.svelte", "*.ts", "*.js", "*.go" },
  callback = function()
    vim.treesitter.start()
  end,
})
