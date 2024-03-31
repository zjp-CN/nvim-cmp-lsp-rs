local M = {}
local lsp = require("cmp.types.lsp")
local kind = lsp.CompletionItemKind
local query = require("cmp_lsp_rs.log").CompletionItemKindStringQuery

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

---@param kinds lsp.CompletionItemKind[]
function M.kind:replace(kinds)
  local ordering = {}
  for idx, k in ipairs(kinds) do
    ordering[k] = idx
  end
  self.ordering = ordering
end

-- Set default ordering
M.kind:replace(kind_ordering)

---@param k cmp_lsp_rs.KindNames | cmp_lsp_rs.KindSelect |cmp_lsp_rs.Kinds
function M.kind:set(k)
  local kinds = {}
  -- FIXME: need to check the range
  if type(k) == "table" then
    if #k == 0 then
      return
    end
    if type(k[1]) == "string" then
      for _, s in ipairs(k) do
        table.insert(kinds, query[s])
      end
    else
      kinds = k
    end
  elseif type(k) == "string" then
    kinds = { query[k] }
  elseif type(k) == "number" then
    kinds = { k }
  elseif type(k) == "function" then
    kinds = k(kind)
  end
  M.kind:replace(merge(kinds))
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
