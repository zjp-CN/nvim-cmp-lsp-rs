local M = {}

M.sort_by_kind = require("cmp_lsp_rs.sort_by_kind").sort_by_kind

---@param data1 cmp_lsp_rs.RACompletionResolveData
---@param data2 cmp_lsp_rs.RACompletionResolveData
M._import = function(data1, data2)
  if #data1.imports == 0 then
    return false
  end
  if #data2.imports == 0 then
    return true
  end

  -- both are imported items
  -- usually RA emits exact one import path and item name;
  -- for multiple same item names, RA will emit distinct completion_items for their own paths
  local import1 = data1.imports[1]
  local import2 = data2.imports[1]
  local path_ord = vim.stricmp(import1.full_import_path, import2.full_import_path)
  if path_ord == -1 then
    -- e1 from lexically less path
    return true
  elseif path_ord == 1 then
    -- e1 from lexically greater path
    return false
  else
    local item_ord = vim.stricmp(import1.imported_name, import2.imported_name)
    if item_ord == 1 then
      return false
    elseif item_ord == -1 then
      return true
    end
  end
end

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M._inherent = function(e1, e2)
  local c1 = e1.completion_item
  local c2 = e2.completion_item

  -- these may be nil
  local l1 = c1.labelDetails.detail
  local l2 = c2.labelDetails.detail

  -- both are in scope
  -- then check the inherent items vs trait items
  local pat = " %(as (.*)%)"
  local trait1 = string.match(l1 or "", pat)
  local trait2 = string.match(l2 or "", pat)

  if trait1 == nil and trait2 == nil then
    -- both are inherent items, then compare by item name
    return nil
  end

  if trait1 == nil then
    -- e1 is inherent item, thus prior
    return true
  end

  if trait2 == nil then
    -- e2 is inherent item, thus prior
    return false
  end

  -- both are trait items, then compare by item name
  local path_ord = vim.stricmp(trait1, trait2)
  if path_ord == -1 then
    return true
  elseif path_ord == 1 then
    return false
  end
  return nil
end

return M
