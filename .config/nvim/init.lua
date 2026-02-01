---@diagnostic disable: undefined-global

vim.opt.rtp:prepend(vim.fn.stdpath("config") .. "/data/folke/lazy.nvim")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.lsp.config('ty', {
  cmd = { 'ty', 'server' },
  settings = {
    ty = {
      -- ty language server settings go here
    }
  }
})
vim.lsp.enable('ty')

vim.lsp.enable('gopls')

vim.cmd([[autocmd BufWritePre * lua vim.lsp.buf.format()]])
vim.api.nvim_set_keymap('n', '<space>', '<cmd>lua vim.lsp.buf.hover()<CR>', { noremap = true, silent = true })

require("lazy").setup({
  spec = {
    { -- comment
      "numToStr/Comment.nvim",
      config = function()
        require("Comment").setup()
      end
    },

    { -- last place
      "ethanholz/nvim-lastplace",
      config = function()
        require("nvim-lastplace").setup {
          lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
          lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
          lastplace_open_folds = true,
        }
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
            ignore = false,
          },
          update_focused_file = {
            enable = true,
            update_root = false,
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
            vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts)
            vim.keymap.set('n', '<CR>', api.node.open.edit, opts)
            vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts)
            vim.keymap.set('n', 'r', api.fs.rename, opts)
            vim.keymap.set('n', 'yy', api.fs.copy.node, opts)
            vim.keymap.set('n', 'y', api.fs.copy.absolute_path, opts)
            vim.keymap.set('n', 'dd', api.fs.cut, opts)
            vim.keymap.set('n', 'p', api.fs.paste, opts)
            vim.keymap.set('n', 'df', api.fs.remove, opts)
            vim.keymap.set('n', 'I', api.tree.toggle_hidden_filter, opts) -- I 键切换隐藏文件显示
            vim.keymap.set('n', '<C-r>', api.tree.reload, opts)           -- R 键重新加载文件树
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
        'mollerhoj/telescope-recent-files.nvim',
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
        telescope.load_extension('recent-files')
      end
    },

    {
      -- treesitter
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require('nvim-treesitter.configs').setup({
          ensure_installed = { "c", "lua", "python", "markdown", "markdown_inline" },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        })
      end
    },

    {
      -- avante
      "yetone/avante.nvim",
      event = "VeryLazy",
      lazy = false,
      opts = {
        debug = true,
        hints = { enabled = false },
        mappings = {
          submit = {
            normal = "<CR>",
            insert = "<CR>",
          },
        },
        -- provider = "claude",
        -- provider = "openai",
        provider = "gemini",
        providers = {
          claude = {
            -- endpoint = "https://babeltower.pro",
            model = "claude-sonnet-4-20250514",
            timeout = 60000, -- Timeout in milliseconds
            -- api_key_name = "BBT_API_KEY",
          },
          gemini = {
            model = "gemini-2.5-pro", -- your desired model (or use gpt-4o, etc.)
            timeout = 30000, -- timeout in milliseconds
            api_key_name = "GEMINI_API_KEY",
          },
          openai = {
            endpoint = "https://babeltower.pro/v1",
            model = "gemini-2.5-pro:google", -- your desired model (or use gpt-4o, etc.)
            timeout = 30000, -- timeout in milliseconds
            api_key_name = "BBT_API_KEY",
          },
          groq = { -- define groq provider
              __inherited_from = 'openai',
              api_key_name = 'GROQ_API_KEY',
              endpoint = 'https://api.groq.com/openai/v1/',
              model = 'llama-3.3-70b-versatile',
              max_tokens = 8192, -- remember to increase this value, otherwise it will stop generating halfway
          },
        },
        disabled_tools = { "python" },
        -- history = {
        --   max_tokens = 0,
        -- },
        cursor_applying_provider = 'groq',
        behaviour = {
          enable_cursor_planning_mode = false,
          auto_apply_diff_after_generation = true,
          enable_claude_text_editor_tool_mode = true,
        },
        vendors = {
        --- ... existing vendors
        },
      },
      -- if you want to download pre-built binary, then pass source=false. Make sure to follow instruction above.
      -- Also note that downloading prebuilt binary is a lot faster comparing to compiling from source.
      build = ":AvanteBuild",
      dependencies = {
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua",      -- for providers='copilot'
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

    {
      -- vscode theme
      "Mofiqul/vscode.nvim",
      commit = "7331e8316d558e9b3f63b066e98029704f281e91",
      config = function()
        vim.cmd [[colorscheme vscode]]
        vim.cmd [[let g:vscode_transparent = 1]]
        vim.cmd [[let g:vscode_italic_comment = 1]]
      end,
    },

    {
      -- copilot
      "zbirenbaum/copilot.lua",
      config = function()
        require("copilot").setup({
          suggestion = {
            enabled = true,
            auto_trigger = true,
            keymap = {
              accept = "<Tab>",
              next = "<C-j>",
              prev = "<C-k>",
            },
          },
          filetypes = {
            ["*"] = true,
          }
        })
      end,
    },
  },
  -- install = { colorscheme = { "vscode" } },
  checker = { enabled = false },
})

-- 在缓存目录保存undo文件
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

vim.opt.number = true
vim.opt.relativenumber = true

-- key binds
vim.keymap.set('n', '<C-f>', require('telescope').extensions['recent-files'].recent_files, { noremap = true, silent = true })
vim.keymap.set('n', '<C-n>', '<cmd>Telescope resume<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-p>', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-g>', function()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({
    default_text = word,
    additional_args = { "--case-sensitive", "--hidden", "--glob", "!.git/*", "--word-regexp" }
  })
end, { noremap = true })

vim.keymap.set('n', '<C-g><C-g>', function()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({
    default_text = word,
    additional_args = { "--case-sensitive", "--hidden", "--glob", "!.git/*" }
  })
end, { noremap = true })

vim.keymap.set('n', '<C-e>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader><Space>', ':AvanteAsk<CR>', { silent = true })
vim.keymap.set('v', '<leader><Space>', require('avante.api').edit, { silent = true })

vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })

vim.keymap.set('i', '<C-h>', '<left>', { silent = true })
vim.keymap.set('i', '<C-l>', '<right>', { silent = true })
vim.keymap.set('i', '<C-j>', '<down>', { silent = true })
vim.keymap.set('i', '<C-k>', '<up>', { silent = true })

vim.keymap.set('n', '<C-j>d', vim.lsp.buf.definition, { noremap = true, silent = true })
vim.keymap.set('n', '<C-j>r', vim.lsp.buf.references, { noremap = true, silent = true })
