local M = {}

M.setup = function()
	print("from nvim-cmp-lsp-rs")
end

print("end of nvim-cmp-lsp-rs")

M.comparators = require("cmp_lsp_rs.comparators")

return M
