local M = {}
-- ---@class RAPushData
-- ---@field uri string
-- ---@field full_import_path string
-- ---@field imported_name string
--
-- ---@class RALabelInfo
-- ---@field label string
-- ---@field kind lsp.CompletionItemKind
-- ---@field data nil | RAPushData

-- ---@param entry cmp.Entry
-- local function entry_to_label_info(entry)
-- 	local c = entry.completion_item
-- 	local data = c.data
-- 	return {
-- 		label = c.label,
-- 		kind = c.kind or 1,
-- 		data = data and {
-- 			uri = data.position.textDocument.uri,
-- 			full_import_path = data.imports[1].full_import_path or "",
-- 			imported_name = data.imports[1].imported_name or "",
-- 		},
-- 	}
-- end

---@class RACompletionImport
---@field full_import_path string
---@field imported_name string

---@class RACompletionResolveData
---@field imports RACompletionImport[]
---@field position lsp.TextDocumentPositionParams

---@alias RAData RACompletionResolveData | nil

---Only compare for rust filetype with nvim_lsp source, which basically means
---sort for completion items emitted by Rust-Analyzer.
---
---The sorting behavior is:
---* in-scope items (items with data field as nil in lsp.CompletionItem)
---  are prior to items that need to be imported
---* inherent items (no `(as xxx)` in filterText field in lsp.CompletionItem)
---  are prior to trait items
---* comparators.sort_by_kind is called inside, meaning no need to put it before this
---  in the comparators list.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.rust_in_scope_or_inherent_first = function(e1, e2)
	local kind_result = require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
	if kind_result ~= nil then
		return kind_result
	end

	if
		e1.context.filetype == "rust"
		and e2.context.filetype == "rust"
		and e1.source.name == "nvim_lsp"
		and e2.source.name == "nvim_lsp"
	then
		local c1 = e1.completion_item
		local c2 = e2.completion_item

		---@type RAData
		local data1 = c1.data
		---@type RAData
		local data2 = c2.data

		local l1 = c1.label
		local l2 = c2.label

		if data1 == nil and data2 == nil then
			-- both are in scope
			-- then check the inherent items vs trait items
			local pat = " %(as (.*)%)"
			local trait1 = l1:match(pat)
			local trait2 = l2:match(pat)

			if trait1 == nil and trait2 == nil then
				-- both are inherent items, then compare by item name
				return (c1.filterText or "") < (c2.filterText or "")
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
			return (c1.filterText or "") < (c2.filterText or "")
		end

		if data2 == nil then
			-- e1 needs to be imported, but e2 not, thus low priority for e1
			return false
		end

		if data1 == nil then
			-- e2 needs to be imported, thus high priority for e1
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
	return nil
end

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.rust_in_scope_inherent_import_with_kind = function(e1, e2)
	if
		e1.context.filetype == "rust"
		and e2.context.filetype == "rust"
		and e1.source.name == "nvim_lsp"
		and e2.source.name == "nvim_lsp"
	then
		return M._in_scope_inherent_import_with_kind(e1, e2)
	end
	return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M._in_scope_inherent_import_with_kind = function(e1, e2)
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

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M._inherent_first = function(e1, e2)
	local c1 = e1.completion_item
	local c2 = e2.completion_item
	local l1 = c1.label
	local l2 = c2.label

	-- both are in scope
	-- then check the inherent items vs trait items
	local pat = " %(as (.*)%)"
	local trait1 = l1:match(pat)
	local trait2 = l2:match(pat)

	if trait1 == nil and trait2 == nil then
		-- both are inherent items, then compare by item name
		return (c1.filterText or "") < (c2.filterText or "")
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
	return (c1.filterText or "") < (c2.filterText or "")
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

---don't sort import path, you'll see alphabetic methods/functions across all imports.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.rust_in_scope_inherent_with_kind = function(e1, e2)
	if
		e1.context.filetype == "rust"
		and e2.context.filetype == "rust"
		and e1.source.name == "nvim_lsp"
		and e2.source.name == "nvim_lsp"
	then
		return M._in_scope_inherent_with_kind(e1, e2)
	end
	return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

---@param e1 cmp.Entry
---@param e2 cmp.Entry
M._in_scope_inherent_with_kind = function(e1, e2)
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

	return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

return M
