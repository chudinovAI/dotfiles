return {
    {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          enabled = false,
        },
        basedpyright = {
          enabled = true,
        },
      },
      diagnostics = {
        virtual_text = false,
      },
    },
    keys = {
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
    },
  },
}