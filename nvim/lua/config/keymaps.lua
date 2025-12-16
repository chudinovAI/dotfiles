local keymap = vim.keymap
local opts = { noremap = true, silent = true }
keymap.set({ "n", "x", "o" }, "H", "^", { desc = "Start of line" })
keymap.set({ "n", "x", "o" }, "L", "g_", { desc = "End of line" })
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")
keymap.set("n", "<C-a>", "gg<S-v>G")
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)
keymap.set("x", "<leader>p", [["_dP]])
keymap.set("n", "<Leader>p", '"0p')
keymap.set("n", "<Leader>P", '"0P')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')
keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "New Tab (Workspace)" })
keymap.set("n", "<leader>tc", ":tabclose<CR>", { desc = "Close Tab" })
keymap.set("n", "<leader><Tab>", ":tabnext<CR>", { desc = "Next Tab" })
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")
keymap.set("n", "J", "mzJ`z")
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<leader>e", function()
  require("telescope").extensions.file_browser.file_browser({
    path = "%:p:h", -- открывать в папке текущего буфера
    select_buffer = true,
  })
end, { desc = "File Browser" })
keymap.set(
  "n",
  "<leader>r",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word under cursor" }
)
keymap.set("n", "'r", function()
  Snacks.picker.grep()
end, { desc = "Grep Text (Snacks)" })
keymap.set("n", "'e", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
keymap.set("n", "'l", function()
  Snacks.picker.lines()
end, { desc = "Lines Finder" })
