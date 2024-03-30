local M = {}

M.setup = function()
  print("from nvim-cmp-lsp-rs")
end

M.kind = require("cmp_lsp_rs.sort_by_kind").kind
M.filter_out = require("cmp_lsp_rs.filter_out")

---Filter out import items the import path of which starts with one of these path prefixes.
---
---The prefix set doesn't affact items already imported in scope. That said if `a::b` is in
---the unwanted_prefix set, but `a::b` is in scope, all items under `a::b` are not import
---items any more, thus they (including trait methods) will appear normally.
M.unwanted_prefix = M.filter_out.rust_unwanted_prefix_for_methods

---Add one or multiple prefix(es) to exclude import items.
---@param prefix string | string[]
M.unwanted_prefix_add = function(prefix)
  if type(prefix) == "string" then
    M.filter_out.rust_unwanted_prefix_for_methods_add({ prefix })
  else
    M.filter_out.rust_unwanted_prefix_for_methods_add(prefix)
  end
end

---Remove one or multiple prefix(es) to exclude import items.
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
