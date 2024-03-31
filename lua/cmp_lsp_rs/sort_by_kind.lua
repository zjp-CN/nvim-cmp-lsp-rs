local M = {}
local lsp = require("cmp.types.lsp")
local kind = lsp.CompletionItemKind

---Default kind ordering.
---@type lsp.CompletionItemKind[]
local kind_ordering = {
  kind.Variable,
  kind.Value,
  kind.Field,
  kind.EnumMember,
  kind.Property,
  kind.TypeParameter,
  kind.Method,
  kind.Module,
  kind.Function,
  kind.Constructor,
  kind.Interface,
  kind.Class,
  kind.Struct,
  kind.Enum,
  kind.Constant,
  kind.Unit,
  kind.Keyword,
  kind.Snippet,
  kind.Color,
  kind.File,
  kind.Folder,
  kind.Event,
  kind.Operator,
  kind.Reference,
  kind.Text,
}

---Merge an incomplete kind list into a default one.
---The input is prior.
---@param kinds lsp.CompletionItemKind[]
local merge = function(kinds)
  -- check the nil or invalid input within the input (whether kinds table has a hole)
  local valid = {}
  local i = 0
  for idx, k in pairs(kinds) do
    i = idx
    if vim.tbl_contains(kind_ordering, k) then
      table.insert(valid, k)
    end
  end
  -- FIXME: there is a bug to pass the check if the last element from input is invalid,
  -- because lua's pairs won't iterate over it. Lua neither seems to provide a good mechanism here...
  if i ~= #valid then
    error(string.format("Some kind is missing. Got %s, but %s invalid kind is found.", i, i - #valid))
  end

  for _, k in ipairs(kind_ordering) do
    if not vim.tbl_contains(valid, k) then
      table.insert(kinds, k)
    end
  end

  return kinds
end

---Ordering for kinds.
---
---CompletionItemKind as the key;
---Order as the value: smaller means higher
---@alias KindOrdering table<lsp.CompletionItemKind, integer>

M.kind = {
  ---@type KindOrdering
  ordering = {},
}

---Construct or update the kind ordering with an array.
---
---The given kinds don't have to be complete lsp.CompletionItemKind list, but
---still recommend to pass a complete ordering list as much as possible,
---in case of poor UX in seeing annoying overlapping kinds on candidates.
---
---If you don't want to write a complete ordering set, use `:update()` instead,
---which handles incomplete ordering set by merging your and the default.
---@param kinds lsp.CompletionItemKind[]
function M.kind:new(kinds)
  local ordering = {}
  for idx, k in ipairs(kinds) do
    ordering[k] = idx
  end
  self.ordering = ordering
end

-- Set default ordering
M.kind:new(kind_ordering)

---Update the kind sorting order with one kind integer or a list of integer or
---a call back that returns a list of integer.
---
---In the callback `function(k)`, you can specify `k.Module` or somthing in lsp
---context to easily write the kinds.
---
---NOTE: the integer is not checked for range. Be careful to the CompletionItemKind
---meaning when you specify it in integer form.
---
---Usaully you pass incomplete kind list in: the rest kinds will be appended
---to the list in the order specified by the default kind ordering in this plugin.
---@param f cmp_lsp_rs.Kinds | cmp_lsp_rs.KindSelect
function M.kind:update(f)
  local kinds = {}
  -- FIXME: need to check the range
  if type(f) == "table" then
    kinds = f
  elseif type(f) == "number" then
    kinds = { f }
  elseif type(f) == "function" then
    kinds = f(kind)
  end
  M.kind:new(merge(kinds))
end

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.sort_by_kind = function(e1, e2)
  local k1 = e1:get_kind()
  local k2 = e2:get_kind()

  -- skip if both are same kind
  if k1 == k2 then
    return nil
  end

  return (M.kind.ordering[k1] or 100) < (M.kind.ordering[k2] or 100)
end

return M
