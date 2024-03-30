local M = {}

---## Example
---
---```lua
---local cmp_rs = require("cmp_lsp_rs")
---local comparators = cmp_rs.comparators
---
---opts.sorting.comparators = {
---  comparators.inherent_import_inscope,
---  comparators.sort_by_label_but_underscore_last,
---}
---```
---
---## Sorting Behaviors
---
---* kind order: Field -> Method -> rest
---  * alphabetic sort on item names separately in the same kind
---  * method order
---    * inherent methods
---      * alphabetic sort on method names
---    * trait methods
---      * in-scope methods
---        * alphabetic sort on trait names in trait methods
---        * alphabetic sort on method names in the same trait
---      * import methods
---          * alphabetic sort on trait names in trait methods
---          * alphabetic sort on method names in the same trait
---
---```rust
---[entry 1] s
---[entry 2] render(…)
---[entry 3] zzzz()
---[entry 4] f() (as AAA)
---[entry 5] z() (as AAA)
---[entry 6] into() (as Into)
---[entry 7] try_into() (as TryInto)
---[entry 8] bg() (use color_eyre::owo_colors::OwoColorize)
---... (use color_eyre::owo_colors::OwoColorize)
---[entry 63] yellow() (use color_eyre::owo_colors::OwoColorize)
---[entry 64] type_id() (use std::any::Any)
---[entry 65] borrow() (use std::borrow::Borrow)
---[entry 66] borrow_mut() (use std::borrow::BorrowMut)
---...
---```
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.inherent_import_inscope = function(e1, e2)
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
local _inherent = function(e1, e2)
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

---@param e1 cmp.Entry
---@param e2 cmp.Entry
local _inscope = function(e1, e2)
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

		return _inherent(e1, e2)
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

---## Example
---
---```lua
---local cmp_rs = require("cmp_lsp_rs")
---local comparators = cmp_rs.comparators
---
---opts.sorting.comparators = {
---  comparators.inscope_inherent,
---  comparators.sort_by_label_but_underscore_last,
---}
---```
---
---## Sorting Behaviors
---
---* in-scope items
---  * kind order: Field -> Method -> rest
---    * alphabetic sort on item names separately in the same kind
---  * method order: inherent -> trait
---    * alphabetic sort on method names in inherent
---    * alphabetic sort on trait names in trait methods
---    * alphabetic sort on method names in the same trait
---* import items
---  * kind order
---    * alphabetic sort on item names separately in the same kind
---
---```rust
---[entry 1] s
---[entry 2] render(…)
---[entry 3] zzzz()
---[entry 4] f() (as AAA)
---[entry 5] z() (as AAA)
---[entry 6] into() (as Into)
---[entry 7] try_into() (as TryInto)
---...
---[entry 78] truecolor(…) (use color_eyre::owo_colors::OwoColorize)
---[entry 79] type_id() (use std::any::Any)
---[entry 80] underline() (use color_eyre::owo_colors::OwoColorize)
---...
---```
---
---NOTE: import path for import items are merely sorted alphabetically,
---no grouping for traits, thus you'll `type_id` is in between non-std methods.
---
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.inscope_inherent = function(e1, e2)
	if
		e1.context.filetype == "rust"
		and e2.context.filetype == "rust"
		and e1.source.name == "nvim_lsp"
		and e2.source.name == "nvim_lsp"
	then
		return _inscope(e1, e2)
	end
	return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

return M
