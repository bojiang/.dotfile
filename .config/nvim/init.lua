vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/data/folke/lazy.nvim")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    {"neovim/nvim-lspconfig"},
    {
      'nvim-telescope/telescope.nvim', tag = '0.1.8',
      dependencies = { 
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-frecency.nvim',
      }
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
      dependencies = {
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua", -- for providers='copilot'
        {
          -- support for image pasting
          "HakonHarnes/img-clip.nvim",
          event = "VeryLazy",
          opts = {
            -- recommended settings
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
          -- Make sure to setup it properly if you have lazy=true
          'MeanderingProgrammer/render-markdown.nvim',
          opts = {
            file_types = { "markdown", "Avante" },
          },
          ft = { "markdown", "Avante" },
        },
      },
    },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

require'lspconfig'.pyright.setup{}


-- telescope
local telescope = require('telescope')
local telescope_builtin = require('telescope.builtin')

telescope.setup({
  extensions = {
    frecency = {
      default_workspace = 'CWD',
      show_unindexed = true,
      ignore_patterns = {"*.git/*", "*/tmp/*", ".venv/*"},
      default_text = '',
    }
  }
})
telescope.load_extension('frecency')



-- key binds
vim.keymap.set('n', '<C-f>', '<cmd>lua require("telescope").extensions.frecency.frecency()<CR>', { noremap = true, silent = true })

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

vim.keymap.set('n', '<C-h>', telescope_builtin.help_tags, {})
