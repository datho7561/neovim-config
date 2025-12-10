-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- configuring base editor features that I like
vim.opt.nu = true
vim.opt.colorcolumn = "81,82,121,122"
vim.opt.cursorline = true
vim.opt.list = true
vim.opt.listchars = "tab:→ ,space:·"
vim.opt.tabstop = 4

vim.diagnostic.config({
  virtual_text = true
})

-- configure lsp shortcuts when the language server starts
local on_attach = function(client, bufnr)
  local function map(mapping, funksion)
    vim.keymap.set("n", mapping, funksion, { buffer = bufnr, noremap = true, silent = true })
  end

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  map("<leader>gd", vim.lsp.buf.definition)
  map("<leader>gD", vim.lsp.buf.type_definition)
  map("<leader>r", vim.lsp.buf.rename)
  map("<leader>a", vim.lsp.buf.code_action)
  map("<leader>gr", require("telescope.builtin").lsp_references)
  -- formatting is handled with a plugin that can shell out to other formatters if needed
end

vim.keymap.set("n", "<leader>lu", function()
  require("lazy").update()
end)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { "tpope/vim-sleuth" },
    {
      "morhetz/gruvbox",
      config = function()
        vim.cmd([[colorscheme gruvbox]])
      end,
    },
    { "lewis6991/gitsigns.nvim" },
    {
      "romgrk/barbar.nvim",
      init = function()
        vim.g.barbar_auto_setup = false
      end,
      dependencies = {
        "lewis6991/gitsigns.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      version = "^1.0.0",
      opts = {
        auto_hide = false,
      },
    },
    { "editorconfig/editorconfig-vim" },
    { -- copied from kickstart.nvim
      -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
    { -- heavily inspired by kickstart.nvim
      "neovim/nvim-lspconfig",
      dependencies = {
        -- Automatically install LSPs and related tools to stdpath for Neovim
        -- Mason must be loaded before its dependents so we need to set it up here.
        -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
        { "mason-org/mason.nvim", opts = {} },
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",

        -- support textDocument/documentLink via gx
        {
          "icholy/lsplinks.nvim",
          config = function()
            local lsplinks = require("lsplinks")
            lsplinks.setup()
            vim.keymap.set("n", "gx", lsplinks.gx)
          end
        },
        -- support textDocument/onTypeFormatting (disabled because it's annoying)
        --{ "yioneko/nvim-type-fmt" },

        -- Useful status updates for LSP.
        { "j-hui/fidget.nvim", opts = {} },

        -- Allows extra capabilities provided by blink.cmp
        "saghen/blink.cmp",
      },
      config = function()

        local M = {}
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        -- list of servers to use and any additional configuration they need on top of the default config
        local servers = {
          eslint = {},
          ts_ls = {},
          jsonls = {},
          rust_analyzer = {},
          lua_ls = {},
          lemminx = {},
          yamlls = {
            settings = {
              yaml = {
                schemastore = {
                  enable = true
                },
                schemas = {
                  ["https://json.schemastore.org/github-workflow.json"] = {".github/workflows/*"},
                  ["kubernetes"] = {"/tmp/kubectl*.yaml"},
                }
              }
            }
          },
          jdtls = {
            handlers = {
              -- when jdtls hits ServiceReady,
              -- toggle inlay hints off then on to properly enable it
              ["language/status"] = function(_, result, ctx, _)
                if result.type == "ServiceReady" and not M.ran_once then
                  vim.lsp.inlay_hint.enable(false)
                  vim.lsp.inlay_hint.enable(true)
                  M.ran_once = true
                end
              end,
            },
            settings = {
              java = {
                inlayHints = {
                  variableTypes = {
                    enabled = true
                  },
                  parameterTypes = {
                    enabled = true
                  }
                }
              }
            }
          }
        }

        -- use mason to ensure the above servers are installed
        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
          "stylua", -- Used to format Lua code
        })
        require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
        vim.lsp.config('*', {
          on_attach = on_attach,
          capabilities = capabilities,
        })

        -- apply any custom configuration
        for server_name, config in pairs(servers) do
          vim.lsp.config(server_name, config)
        end

        require("mason-lspconfig").setup({
          ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
          automatic_installation = false,
          automatic_enable = true,
        })
      end,
    },
    { -- Autocompletion (taken from kickstart.nvim)
      "saghen/blink.cmp",
      event = "VimEnter",
      version = "1.*",
      dependencies = {
        -- Snippet Engine
        {
          "L3MON4D3/LuaSnip",
          version = "2.*",
          build = (function()
            -- Build Step is needed for regex support in snippets.
            -- This step is not supported in many windows environments.
            -- Remove the below condition to re-enable on windows.
            if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
              return
            end
            return "make install_jsregexp"
          end)(),
          dependencies = {
            -- `friendly-snippets` contains a variety of premade snippets.
            --    See the README about individual language/framework/plugin snippets:
            --    https://github.com/rafamadriz/friendly-snippets
            -- {
            --   'rafamadriz/friendly-snippets',
            --   config = function()
            --     require('luasnip.loaders.from_vscode').lazy_load()
            --   end,
            -- },
          },
          opts = {},
        },
        "folke/lazydev.nvim",
      },
      --- @module 'blink.cmp'
      --- @type blink.cmp.Config
      opts = {
        keymap = {
          -- 'default' (recommended) for mappings similar to built-in completions
          --   <c-y> to accept ([y]es) the completion.
          --    This will auto-import if your LSP supports it.
          --    This will expand snippets if the LSP sent a snippet.
          -- 'super-tab' for tab to accept
          -- 'enter' for enter to accept
          -- 'none' for no mappings
          --
          -- For an understanding of why the 'default' preset is recommended,
          -- you will need to read `:help ins-completion`
          --
          -- No, but seriously. Please read `:help ins-completion`, it is really good!
          --
          -- All presets have the following mappings:
          -- <tab>/<s-tab>: move to right/left of your snippet expansion
          -- <c-space>: Open menu or open docs if already open
          -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
          -- <c-e>: Hide menu
          -- <c-k>: Toggle signature help
          --
          -- See :h blink-cmp-config-keymap for defining your own keymap
          preset = "enter",

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },

        appearance = {
          -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          -- Adjusts spacing to ensure icons are aligned
          nerd_font_variant = "mono",
        },

        completion = {
          -- By default, you may press `<c-space>` to show the documentation.
          -- Optionally, set `auto_show = true` to show the documentation after a delay.
          documentation = { auto_show = false, auto_show_delay_ms = 500 },
        },

        sources = {
          default = { "lsp", "path", "snippets", "lazydev" },
          providers = {
            lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
          },
        },

        snippets = { preset = "luasnip" },

        -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
        -- which automatically downloads a prebuilt binary when enabled.
        --
        -- By default, we use the Lua implementation instead, but you may enable
        -- the rust implementation via `'prefer_rust_with_warning'`
        --
        -- See :h blink-cmp-config-fuzzy for more information
        fuzzy = { implementation = "lua" },

        -- Shows a signature help window while you type arguments for a function
        signature = { enabled = true },
      },
    },
    { -- Autoformat (also copied from kickstart.nvim)
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      cmd = { "ConformInfo" },
      keys = {
        {
          "<leader>F",
          function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end,
          mode = "",
          desc = "[F]ormat buffer",
        },
      },
      opts = {
        notify_on_error = false,
        formatters_by_ft = {
          lua = { "stylua" },
          -- Conform can also run multiple formatters sequentially
          -- python = { "isort", "black" },
          --
          -- You can use 'stop_after_first' to run the first available formatter from the list
          -- javascript = { "prettierd", "prettier", stop_after_first = true },
        },
      },
    },
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.8",
      dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
      init = function()
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>f", builtin.find_files)
        vim.keymap.set("n", "<leader>/", builtin.live_grep)
        vim.keymap.set("n", "<leader>b", builtin.buffers)
      end,
    },
    -- copied from kickstart.nvim
    { -- Highlight, edit, and navigate code
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      main = "nvim-treesitter.configs", -- Sets main module to use for opts
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
      opts = {
        ensure_installed = {
          "bash",
          "c",
          "diff",
          "html",
          "lua",
          "luadoc",
          "java",
          "markdown",
          "markdown_inline",
          "query",
          "vim",
          "vimdoc",
          "yaml",
        },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = {
          enable = true,
          -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
          --  If you are experiencing weird indenting issues, add the language to
          --  the list of additional_vim_regex_highlighting and disabled languages for indent.
          additional_vim_regex_highlighting = { "ruby" },
        },
        indent = { enable = true, disable = { "ruby", "yaml" } },
      },
    },
  },
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "gruvbox" } },
})
