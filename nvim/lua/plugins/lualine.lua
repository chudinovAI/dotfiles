return {
    {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local function get_tools()
        local tools = {}
        local seen = {}

        local clients = vim.lsp.get_clients({ bufnr = 0 })
        for _, client in ipairs(clients) do
          if client.name ~= "null-ls" and client.name ~= "copilot" then
            if not seen[client.name] then
              table.insert(tools, client.name)
              seen[client.name] = true
            end
          end
        end

        local ok, conform = pcall(require, "conform")
        if ok then
          for _, formatter in ipairs(conform.list_formatters(0)) do
            local name = formatter.name
            if not seen[name] then
              table.insert(tools, name)
              seen[name] = true
            end
          end
        end

        return #tools > 0 and "{} " .. table.concat(tools, ", ") or ""
      end

      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = ""
      opts.options.globalstatus = true

      opts.sections.lualine_a = {
        {
          function()
            return " " .. vim.fn.hostname()
          end,
          cond = function()
            return os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY")
          end,
          padding = { left = 1, right = 1 },
        },
        { "mode" },
      }

      opts.sections.lualine_b = {
        "branch",
        {
          "diff",
          symbols = { added = "[+] ", modified = "[~] ", removed = "[-] " },
        },
      }

      opts.sections.lualine_c = {
        require("lazyvim.util").lualine.pretty_path(),
      }

      opts.sections.lualine_x = {
        {
          "diagnostics",
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
        {
          get_tools,
        },
      }

      opts.sections.lualine_y = {
        {
          "encoding",
          cond = function()
            return vim.bo.fileencoding ~= "utf-8"
          end,
        },
        {
          function()
            local venv = os.getenv("VIRTUAL_ENV")
            return venv and vim.fn.fnamemodify(venv, ":t") or ""
          end,
          cond = function()
            return vim.bo.filetype == "python"
          end,
        },
      }

      opts.sections.lualine_z = {
        { "searchcount" },
        { "location" },
      }

      return opts
    end,
  },
}