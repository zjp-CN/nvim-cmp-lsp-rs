local M = {}

---@param source cmp.SourceConfig
M.entry_filter = function(source)
  if source.name == "nvim_lsp" then
    source.entry_filter = M.rust_entry_filter
  end
end

---A set of path prefix that a to-be-imported method starts with and you don't want
---the method pops up.
---
---The prefix can be `a_crate_name` or `module_name` or `path::name`.
---
---Only literal prefix is supported: no regex matching yet.
---
---Non-methods and methods already brought in scope in these crates will
---be not filtered out and still usable as usual.
---@type string[]
M.rust_unwanted_prefix_for_methods = {}

---Append given crates to current unwanted set.
---
---Other updating behavior:
---* use `filter_out:rust_unwanted_prefix_for_methods = { ... }` to override
---* use `filter_out:rust_unwanted_prefix_for_methods_remove({...})` to remove
---@param crates string[]
function M.rust_unwanted_prefix_for_methods_add(crates)
  for _, crate in ipairs(crates) do
    table.insert(M.rust_unwanted_prefix_for_methods, crate)
  end

  -- deduplicate prefixes
  local keep = {}
  for _, crate in ipairs(M.rust_unwanted_prefix_for_methods) do
    keep[crate] = true
  end

  M.rust_unwanted_prefix_for_methods = {}
  for crate, _ in pairs(keep) do
    table.insert(M.rust_unwanted_prefix_for_methods, crate)
  end
end

---Remove given crates from current unwanted set.
---
---Other updating behavior:
---* use `filter_out:rust_unwanted_prefix_for_methods = { ... }` to override
---* use `filter_out:rust_unwanted_prefix_for_methods_add({...})` to append
---@param crates string[]
function M.rust_unwanted_prefix_for_methods_remove(crates)
  local remove = {}
  for _, crate in ipairs(crates) do
    remove[crate] = true
  end

  local keep = {}
  for _, crate in ipairs(M.rust_unwanted_prefix_for_methods) do
    if not remove[crate] then
      table.insert(keep, crate)
    end
  end

  M.rust_unwanted_prefix_for_methods = keep
end

---Only filter out candidates for rust filetype.
---@param entry cmp.Entry
---@param ctx cmp.Context
M.rust_entry_filter = function(entry, ctx)
  if ctx.filetype == "rust" then
    return M.rust_filter_out_methods_to_be_imported(entry)
  end

  -- keep for other filetypes
  return true
end

---@param entry cmp.Entry
M.rust_filter_out_methods_to_be_imported = function(entry)
  ---@type RAData
  local data = entry.completion_item.data

  -- only filter out imported methods
  if data == nil or #data.imports == 0 or entry:get_kind() ~= 2 then
    return true
  end

  for _, to_be_import in ipairs(data.imports) do
    -- can be crate name or module name
    -- local name = to_be_import.full_import_path:match("%w+")
    for _, unwanted_prefix in ipairs(M.rust_unwanted_prefix_for_methods) do
      if vim.startswith(to_be_import.full_import_path, unwanted_prefix) then
        return false
      end
    end
  end

  return true
end

return M
