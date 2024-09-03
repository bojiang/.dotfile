vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/data/folke/lazy.nvim")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    { -- ls & format
      "neovim/nvim-lspconfig",
      dependencies = {
        "lukas-reineke/lsp-format.nvim",
        "nmac427/guess-indent.nvim",
      },
      config = function()
        require('guess-indent').setup {}
        require("lsp-format").setup {}
        require("lspconfig").pyright.setup { on_attach = require("lsp-format").on_attach }
        require("lspconfig").lua_ls.setup { on_attach = require("lsp-format").on_attach }
      end
    },
    { -- tree
      "nvim-tree/nvim-tree.lua",
      config = function()
        require("nvim-tree").setup({
          view = {
            width = 40,
            side = 'left',
          },
          git = {
            enable = true,
          },
          renderer = {
            icons = {
              show = {
                git = true,
                folder = true,
                file = true,
                folder_arrow = true,
              },
            },
          },
          on_attach = function(bufnr)
            local api = require('nvim-tree.api')
            local opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }

            vim.keymap.set('n', '<C-e>', api.tree.toggle, opts)
            vim.keymap.set('n', 'l', api.node.open.edit, opts)
            vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts) -- 双击左键打开文件或目录
            -- vim.keymap.set('n', 'v', api.node.open.vertical, opts)         -- v 键垂直分割窗口打开文件
            -- vim.keymap.set('n', 's', api.node.open.horizontal, opts)       -- s 键水平分割窗口打开文件
            vim.keymap.set('n', 'I', api.tree.toggle_hidden_filter, opts) -- I 键切换隐藏文件显示
            vim.keymap.set('n', 'R', api.tree.reload, opts)               -- R 键重新加载文件树
            vim.keymap.set('n', '<Space>', api.node.open.preview, opts)
          end
        })
      end
    },
    { -- lists
      'nvim-telescope/telescope.nvim',
      tag = '0.1.8',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-frecency.nvim',
      },
      config = function()
        local telescope = require('telescope')
        telescope.setup({
          extensions = {
            frecency = {
              default_workspace = 'CWD',
              show_unindexed = true,
              ignore_patterns = { "*.git/*", "*/tmp/*", ".venv/*" },
              default_text = '',
            }
          },
          defaults = {
            mappings = {
              i = {
                ["<C-j>"] = "move_selection_next",
                ["<C-k>"] = "move_selection_previous",
              },
            },
          },
        })
        telescope.load_extension('frecency')
      end
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require('nvim-treesitter.configs').setup({
          ensure_installed = { "c", "lua", "python" },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        })
      end
    },
    {
      "yetone/avante.nvim",
      event = "VeryLazy",
      lazy = false,
      opts = {
        -- add any opts here
      },
      build = ":AvanteBuild", -- This is optional, recommended tho. Also note that this will block the startup for a bit since we are compiling bindings in Rust.
      config = function()
        require("copilot").setup({
          suggestion = {
            enabled = true,
            auto_trigger = true,
          },
          filetypes = {
            ["*"] = true,
          }
        })
      end,
      dependencies = {
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua",      -- for providers='copilot'
        {
          -- support for image pasting
          "HakonHarnes/img-clip.nvim",
          event = "VeryLazy",
          opts = {
            default = {
              embed_image_as_base64 = false,
              prompt_for_file_name = false,
              drag_and_drop = {
                insert_mode = true,
              },
              -- required for Windows users
              -- use_absolute_path = true,
            },
          },
        },
        {
          'MeanderingProgrammer/render-markdown.nvim',
          opts = {
            file_types = { "markdown", "Avante" },
          },
          ft = { "markdown", "Avante" },
        },
      },
    },
    { "Mofiqul/vscode.nvim" },
  },
  install = { colorscheme = { "vscode" } },
  checker = { enabled = true },
})




-- VSCode theme
vim.cmd [[colorscheme vscode]]
vim.cmd [[let g:vscode_transparent = 1]]
vim.cmd [[let g:vscode_italic_comment = 1]]



-- key binds
vim.keymap.set('n', '<C-f>', '<cmd>lua require("telescope").extensions.frecency.frecency()<CR>',
  { noremap = true, silent = true })

vim.keymap.set('n', '<C-g>', '', {
  noremap = true,
  callback = function()
    local word = vim.fn.expand('<cword>')
    telescope_builtin.live_grep({
      default_text = word,
      additional_args = function(opts)
        return { "--case-sensitive" }
      end
    })
  end
})


vim.keymap.set({ 'n', 'i' }, '<C-e>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader><Space>', ':AvanteAsk<CR>', { silent = true })

vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })

vim.keymap.set('i', '<C-h>', '<left>', { silent = true })
vim.keymap.set('i', '<C-l>', '<right>', { silent = true })
vim.keymap.set('i', '<C-j>', '<down>', { silent = true })
vim.keymap.set('i', '<C-k>', '<up>', { silent = true })
