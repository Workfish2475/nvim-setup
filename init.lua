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
				virtual_text = true, -- set to false to hide inline text
				signs = false, -- set to false to hide E/W signs in the sign column
				update_in_insert = false, -- set to true to show errors while typing
				float = {
					source = "always",
					border = "single",
				},
			})

			vim.opt.number = true

			-- Standard LSP capabilities
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Add the servers you want automatically installed here
			local servers = {
				lua_ls = {
					settings = {
						Lua = { completion = { callSnippet = "Replace" } },
					},
				},
                svelte = {
                  -- Use the standard name; Mason-lspconfig will find it in your path
                  cmd = { "svelte-language-server", "--stdio" },
                },
				pyright = {},
				ts_ls = {
                filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
                -- This prevents ts_ls from trying to run inside .svelte files
            },
			}

			-- Ensure tools (like formatters) are installed
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
		priority = 1000
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
            'bash', 'html', 'lua', 'svelte', 'typescript', 'javascript', 'css' 
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
		"navarasu/onedark.nvim",
		version = "v0.1.0",
		priority = 1000,
		config = function()
			require("onedark").setup({
				style = "darker",
			})
			require("onedark").load()
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {}
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		build = "make install_jsregexp"
	},
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = { "*.svelte", "*.ts", "*.js" },
  callback = function()
    vim.treesitter.start()
  end,
})
