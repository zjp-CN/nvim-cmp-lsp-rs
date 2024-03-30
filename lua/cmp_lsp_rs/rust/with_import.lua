local M = {}

---@param e1 cmp.Entry
---@param e2 cmp.Entry
local _locality_wins_with_import = function(e1, e2)
	local c1 = e1.completion_item
	local c2 = e2.completion_item

	---@type RAData
	local data1 = c1.data
	---@type RAData
	local data2 = c2.data

	if data1 == nil and data2 == nil then
		local kind_result = require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
		if kind_result ~= nil then
			return kind_result
		end

		return M._inherent_first(e1, e2)
	end

	if data2 == nil then
		-- e1 needs to be imported, but e2 not, thus low priority for e1
		return false
	end

	if data1 == nil then
		-- e2 needs to be imported, thus high priority for e1
		return true
	end

	local kind_result = require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
	if kind_result ~= nil then
		return kind_result
	end

	return M._import(data1, data2)
end

---@param data1 RACompletionResolveData
---@param data2 RACompletionResolveData
M._import = function(data1, data2)
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
M.locality_wins_with_import = function(e1, e2)
	if
		e1.context.filetype == "rust"
		and e2.context.filetype == "rust"
		and e1.source.name == "nvim_lsp"
		and e2.source.name == "nvim_lsp"
	then
		return _locality_wins_with_import(e1, e2)
	end
	return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

return M
