local plenary_path = "/tmp/plenary.nvim"

if vim.fn.isdirectory(plenary_path) == 0 then
  print("Cloning plenary.nvim...")
  vim.fn.system({ "git", "clone", "--depth=1", "https://github.com/nvim-lua/plenary.nvim", plenary_path })
end

vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend(plenary_path)

vim.cmd("runtime plugin/plenary.vim")
