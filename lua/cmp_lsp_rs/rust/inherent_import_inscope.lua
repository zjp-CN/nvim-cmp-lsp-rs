local M = {}
local util = require("cmp_lsp_rs.rust.util")

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
  local kind_result = util.sort_by_kind(e1, e2)
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

    if data1 == nil and data2 == nil then
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

    return util._import(data1, data2)
  end
  return nil
end

return M
