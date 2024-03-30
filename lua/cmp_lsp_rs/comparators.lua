local lsp = require("cmp.types.lsp")
local kind = lsp.CompletionItemKind

local M = {}

---@type lsp.CompletionItemKind[]
M.kind_ordering = {
	kind.Variable,
	kind.Value,
	kind.Field,
	kind.EnumMember,
	kind.Property,
	kind.TypeParameter,
	kind.Method,
	kind.Function,
	kind.Constructor,
	kind.Interface,
	kind.Class,
	kind.Struct,
	kind.Enum,
	kind.Constant,
	kind.Unit,
	kind.Keyword,
	kind.Module,
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
		if vim.tbl_contains(M.kind_ordering, k) then
			table.insert(valid, k)
		end
	end
	-- FIXME: there is a bug to pass the check if the last element from input is invalid,
	-- because lua's pairs won't iterate over it. Lua neither seems to provide a good mechanism here...
	if i ~= #valid then
		error(string.format("Some kind is missing. Got %s, but %s invalid kind is found.", i, i - #valid))
	end

	for _, k in ipairs(M.kind_ordering) do
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
-- for idx, k in ipairs(M.kind_ordering) do
-- 	M.kind[k] = idx
-- end
-- print(vim.inspect(M.kind))

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
M.kind:new(M.kind_ordering)

---@class CompletionItemKind
---@field Text integer
---@field Method integer
---@field Function integer
---@field Constructor integer
---@field Field integer
---@field Variable integer
---@field Class integer
---@field Interface integer
---@field Module integer
---@field Property integer
---@field Unit integer
---@field Value integer
---@field Enum integer
---@field Keyword integer
---@field Snippet integer
---@field Color integer
---@field File integer
---@field Reference integer
---@field Folder integer
---@field EnumMember integer
---@field Constant integer
---@field Struct integer
---@field Event integer
---@field Operator integer
---@field TypeParameter integer

---Update the kind sorting order with call back.
---
---In the callback `function(k)`, you can specify `k.Module` or somthing
---to easily write the kinds.
---@param f fun(kind: CompletionItemKind): lsp.CompletionItemKind[]
function M.kind:update(f)
	local kinds = f(kind)
	M.kind:new(merge(kinds))
end

-- ---@param k CompletionItemKind
-- M.kind:update(function(k)
-- 	return {
-- 		k.Module,
-- 		k.Variable,
-- 	}
-- end)
-- print(vim.inspect(M.kind))

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

M.locality_wins_with_import = require("cmp_lsp_rs.rust").locality_wins_with_import
M.inherent_import_inscope = require("cmp_lsp_rs.rust").inherent_import_inscope
M.inscope_inherent = require("cmp_lsp_rs.rust").inscope_inherent

return M
