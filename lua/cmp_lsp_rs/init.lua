local M = {}

M.setup = function()
	print("from nvim-cmp-lsp-rs")
end

print("end of nvim-cmp-lsp-rs")

M.filter_out = require("cmp_lsp_rs.filter_out")
M.unwanted_prefix = M.filter_out.rust_unwanted_prefix_for_methods

---@param prefix string | string[]
M.unwanted_prefix_add = function(prefix)
	if type(prefix) == "string" then
		M.filter_out.rust_unwanted_prefix_for_methods_add({ prefix })
	else
		M.filter_out.rust_unwanted_prefix_for_methods_add(prefix)
	end
end

---@param prefix string | string[]
M.unwanted_prefix_remove = function(prefix)
	if type(prefix) == "string" then
		M.filter_out.rust_unwanted_prefix_for_methods_remove({ prefix })
	else
		M.filter_out.rust_unwanted_prefix_for_methods_remove(prefix)
	end
end

M.comparators = require("cmp_lsp_rs.comparators")
M.log = require("cmp_lsp_rs.log")

return M
