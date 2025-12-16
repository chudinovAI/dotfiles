return {
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    priority = 1200,
    config = function()
      require("incline").setup({
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = {
          cursorline = true,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          return { { filename } }
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },
  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    config = true,
  },
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        show_close_icon = false,
        show_buffer_close_icons = false,
      },
    },
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      message_template = " <date> • <author>",
      date_format = "%m-%d-%Y",
      virtual_text_column = 0,
      display_virtual_text = false,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      indent = { enable = false },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local LazyVim = require("lazyvim.util")
      local git_blame = require("gitblame")
      local function fg(name)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        return hl.fg and string.format("#%06x", hl.fg) or "NONE"
      end
      return {
        options = {
          globalstatus = true,
          component_separators = "",
          section_separators = { left = "", right = "" },
          theme = "auto",
          disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard", "alpha" } },
        },
        sections = {
          lualine_a = {
            {
              function()
                if os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY") then
                  return " " .. vim.fn.hostname()
                end
                return ""
              end,
              color = { fg = fg("Normal"), bg = fg("Constant") },
              padding = { left = 1, right = 1 },
              cond = function()
                return os.getenv("SSH_CLIENT") ~= nil
              end,
            },
            { "mode" },
          },
          lualine_b = { "branch", "diff" },
          lualine_c = {
            { LazyVim.lualine.pretty_path() },
            { git_blame.get_current_blame_text, cond = git_blame.is_blame_text_available },
          },
          lualine_x = {
            {
              "diagnostics",
              sources = { "nvim_lsp" },
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
            {
              function()
                local status, conform = pcall(require, "conform")
                if not status then
                  return ""
                end
                local formatters = conform.list_formatters(0)
                return #formatters > 0 and (" " .. formatters[1].name) or ""
              end,
              color = { fg = fg("Function") },
            },
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if not next(clients) then
                  return ""
                end
                local names = {}
                for _, client in ipairs(clients) do
                  if client.name ~= "null-ls" and client.name ~= "copilot" then
                    table.insert(names, client.name)
                  end
                end
                return "{} " .. table.concat(names, ", ")
              end,
              color = { fg = fg("Normal") },
            },
          },
          lualine_y = {
            {
              "encoding",
              fmt = string.upper,
              cond = function()
                return vim.bo.fileencoding ~= "utf-8"
              end,
              color = { fg = fg("DiagnosticError") },
            },
            {
              function()
                local venv = os.getenv("VIRTUAL_ENV")
                return venv and (" " .. string.match(venv, "([^/]+)$")) or ""
              end,
              cond = function()
                return vim.bo.filetype == "python"
              end,
              color = { fg = fg("String") },
            },
          },
          lualine_z = {
            {
              "searchcount",
              cond = function()
                return vim.v.hlsearch ~= 0 and vim.fn.searchcount({ recompute = 1 }).total > 0
              end,
            },
            { "location" },
          },
        },
      }
    end,
  },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.notify = { enabled = false }
      opts.lsp = opts.lsp or {}
      opts.lsp.signature = opts.lsp.signature or {}
      opts.lsp.signature.auto_open = { enabled = false }
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      opts.commands = {
        all = {
          view = "split",
          opts = { enter = true, format = "details" },
          filter = {},
        },
      }
      opts.presets.lsp_doc_border = true
    end,
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 10000,
      background_colour = "#000000",
    },
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local fb_actions = require("telescope._extensions.file_browser.actions")
      local actions = require("telescope.actions")

      require("telescope").setup({
        extensions = {
          file_browser = {
            theme = "dropdown",
            hijack_netrw = true,
            path = vim.loop.cwd(),
            files = true,
            hidden = true,
            respect_gitignore = vim.fn.executable("fd") == 1,
            git_status = true,
            mappings = {
              ["n"] = {
                ["N"] = fb_actions.create,
                ["h"] = fb_actions.goto_parent_dir,
                ["/"] = function()
                  vim.cmd("startinsert")
                end,
              },
            },
          },
        },
      })

      require("telescope").load_extension("file_browser")
    end,
  },
}
