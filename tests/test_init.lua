--Call the vim-plug using the vimscript methods since vim plug does not have native lua calls.
-- local Plug = vim.fn["plug#"]
-- vim.call("plug#begin")
-- Plug("nvim-lua/plenary.nvim")
-- Plug("~/source/repos/Solution.nvim")
-- vim.call("plug#end")
--
local parent_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":h")

print("Adding directory " .. parent_dir)
vim.opt.runtimepath:append(parent_dir)

--vim.opt.runtimepath:append('..')
