local M = {}

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

---Sort only by label in alphabetic order, but if the fisrt letter is
---underscore `_`, put it to the last.
---If both start with `_`, return nil and compare them later with
---`sort_underscore`, which is like `sort_by_label_but_underscore_last`,
---but gives a bit more control on underscore case.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.sort_by_label_but_underscore_nil = function(e1, e2)
  local l1 = e1.completion_item.label
  local l2 = e2.completion_item.label
  local e1_starts_ = vim.startswith(l1, "_")
  local e2_starts_ = vim.startswith(l2, "_")

  -- local f = io.open("entries.log", "w+")
  -- if f then
  --   f:write(string.format("l1 = %s\nl2 = %s\n\n", l1, l2))
  -- end

  if e1_starts_ and e2_starts_ then
    return nil
  end

  if e1_starts_ then
    -- `_xxx` vs `yyy`
    return false
  end

  if e2_starts_ then
    -- `yyy` vs `_xxx`
    return true
  end

  -- `xxx` vs `yyy` (no`_xxx` vs `_yyy` any more)
  return l1 < l2
end

---Put this after `sort_by_label_but_underscore_nil`.
---@param e1 cmp.Entry
---@param e2 cmp.Entry
M.sort_underscore = function(e1, e2)
  return (e1.completion_item.filterText or e1.completion_item.label)
    < (e2.completion_item.filterText or e2.completion_item.label)
end

return M
