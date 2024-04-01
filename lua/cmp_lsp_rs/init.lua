local M = {}

---In case of setup failure for nvim-cmp, you can call this function to
---override configuration on it when nvim-cmp is fully loaded.
M.force_set_cmp = function()
  local cmp = require("cmp")
  local opts = cmp.get_config()
  opts.sorting.comparators = {
    M.comparators.inscope_inherent_import,
    M.comparators.sort_by_label_but_underscore_last,
  }

  for _, source in ipairs(opts.sources) do
    M.filter_out.entry_filter(source)
  end
end

---@param opts cmp_lsp_rs.Opts | nil
M.setup = function(opts)
  if not opts then
    return
  end

  if opts.kind then
    M.kind.set(opts.kind)
  end

  if opts.unwanted_prefix then
    M.unwanted_prefix.add(opts.unwanted_prefix)
  end

  if opts.combo then
    -- override comparators
    M.combo.comparators = {}
    M.combo.names = {}
    M.combo.pos = 0
    for name, combo in pairs(opts.combo) do
      if type(combo) == "table" then
        table.insert(M.combo.comparators, combo)
      else
        table.insert(M.combo.comparators, combo())
      end
      table.insert(M.combo.names, name)
    end
  end
end

M.kind = {}

local kind = require("cmp_lsp_rs.sort_by_kind").kind

---Get the current kind ordering in human-read form.
M.kind.get = function()
  local set = require("cmp_lsp_rs.log").CompletionItemKindString
  local ordering = {}
  for _, k in ipairs(kind.ordering) do
    table.insert(ordering, set[k])
  end
  return set
end

---Set the kinds with most priorities.
---
---This will update the kind sorting order with one kind or a list of kind
---or a call back that returns a list of integer.
---
---A kind can be lsp.CompletionItemKind integer or a string name.
---
---In the callback `function(k)`, you can specify `k.Module` or somthing in lsp
---context to easily write the kinds.
---
---NOTE: the integer is not checked for range. Be careful to the CompletionItemKind
---meaning when you specify it in integer form.
---
---Usaully you pass incomplete kind list in, and the rest kinds will be appended
---to the list in the order specified by the default kind ordering in this plugin.
---@param kinds cmp_lsp_rs.KindNames | cmp_lsp_rs.KindSelect | cmp_lsp_rs.Kinds
M.kind.set = function(kinds)
  kind:set(kinds)
end

M.filter_out = require("cmp_lsp_rs.filter_out")

M.unwanted_prefix = {}

M.unwanted_prefix.get = function()
  return M.filter_out.rust_unwanted_prefix_for_methods
end

---Override prefix(es) to exclude import methods.
---
---Filter out import methods the import path of which starts with one of these path prefixes.
---
---The prefix set doesn't affact items already imported in scope. That said if `a::b` is in
---the unwanted_prefix set, but `a::b` is in scope, all items under `a::b` are not import
---items any more, thus they (including trait methods) will appear normally.
---@param prefix string | string[]
M.unwanted_prefix.set = function(prefix)
  if type(prefix) == "string" then
    M.filter_out.rust_unwanted_prefix_for_methods_set({ prefix })
  else
    M.filter_out.rust_unwanted_prefix_for_methods_set(prefix)
  end
end

---Add one or multiple prefix(es) to exclude import methods.
---@param prefix string | string[]
M.unwanted_prefix.add = function(prefix)
  if type(prefix) == "string" then
    M.filter_out.rust_unwanted_prefix_for_methods_add({ prefix })
  else
    M.filter_out.rust_unwanted_prefix_for_methods_add(prefix)
  end
end

---Remove one or multiple prefix(es) to exclude import methods.
---@param prefix string | string[]
M.unwanted_prefix.remove = function(prefix)
  if type(prefix) == "string" then
    M.filter_out.rust_unwanted_prefix_for_methods_remove({ prefix })
  else
    M.filter_out.rust_unwanted_prefix_for_methods_remove(prefix)
  end
end

M.comparators = require("cmp_lsp_rs.comparators")
M.log = require("cmp_lsp_rs.log")

M.combo = setmetatable({
  pos = 0,
  comparators = {
    { M.comparators.inherent_import_inscope, M.comparators.sort_by_label },
    { M.comparators.inscope_inherent_import, M.comparators.sort_by_label },
  },
  names = {
    "inherent_import_inscope + sort_by_label",
    "inscope_inherent_import + sort_by_label",
  },
}, {
  __call = function(t)
    t.pos = t.pos % #t.comparators + 1
    require("cmp").get_config().sorting.comparators = t.comparators[t.pos]
    local msg = string.format("[nvim-cmp] Comparators have switched to: %s", t.names[t.pos])
    vim.notify(msg, vim.log.levels.INFO)
  end,
})

return M
