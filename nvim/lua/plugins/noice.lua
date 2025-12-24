return {
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
}