local M = {}
local util = require("cmp_lsp_rs.rust.util")

---@param e1 cmp.Entry
---@param e2 cmp.Entry
local _inscope_inherent = function(e1, e2)
  local c1 = e1.completion_item
  local c2 = e2.completion_item

  ---@type cmp_lsp_rs.RAData
  local data1 = c1.data
  ---@type cmp_lsp_rs.RAData
  local data2 = c2.data

  if data1 == nil and data2 == nil then
    local kind_result = util.sort_by_kind(e1, e2)
    if kind_result ~= nil then
      return kind_result
    end

    return util._inherent(e1, e2)
  end

  if data2 == nil then
    -- e1 needs to be imported, but e2 not, thus low priority for e1
    return false
  end

  if data1 == nil then
    -- e2 needs to be imported, thus high priority for e1
    return true
  end

  return util.sort_by_kind(e1, e2)
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
    return _inscope_inherent(e1, e2)
  end
  return require("cmp_lsp_rs.comparators").sort_by_kind(e1, e2)
end

return M
