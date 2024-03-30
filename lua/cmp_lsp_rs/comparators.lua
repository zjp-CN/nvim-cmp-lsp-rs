local M = {}
local rust = require("cmp_lsp_rs.rust")

---Sort only by label in alphabetic order.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.sort_by_label = function(e1, e2)
  return e1.completion_item.label < e2.completion_item.label
end

---Sort only by label in alphabetic order, but if the fisrt letter is
---underscore `_`, put it to the last.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.sort_by_label_but_underscore_last = function(e1, e2)
  local l1 = e1.completion_item.label
  local l2 = e2.completion_item.label
  local e1_starts_ = vim.startswith(l1, "_")
  local e2_starts_ = vim.startswith(l2, "_")

  if e1_starts_ then
    if not e2_starts_ then
      -- `_xxx` vs `yyy`
      return false
    end
  end

  if e2_starts_ then
    if not e1_starts_ then
      -- `yyy` vs `_xxx`
      return true
    end
  end

  -- `xxx` vs `yyy` or `_xxx` vs `_yyy`
  return l1 < l2
end

M.sort_by_kind = require("cmp_lsp_rs.sort_by_kind").sort_by_kind

M.inherent_import_inscope = rust.inherent_import_inscope
M.inscope_inherent = rust.inscope_inherent
M.inscope_inherent_import = rust.inscope_inherent_import

return M
