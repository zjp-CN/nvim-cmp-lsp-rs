local M = {}

---Log for completion candidates on rust file / Rust-Analyzer.
---Always record the latest completion list.
---The list is sorted in order by comparators you set up,
---which agrees with what the menu popup displays.
M.register = function()
  local cmp = require("cmp")

  -- menu_opened is emitted from nvim-cmp after the entries are sorted
  -- and before being passed to the view/ui.
  cmp.event:on("menu_opened", function()
    if cmp.core.context.filetype ~= "rust" then
      return
    end

    local log = io.open("entries.log", "w+")
    if not log then
      return
    end

    local kind_string = M.CompletionItemKindString
    local entries = cmp.core.view:get_entries()
    for idx, entry in ipairs(entries) do
      local item = entry.completion_item
      log:write(
        string.format(
          "[entry %s] %s\n  filter_text: %s\n  kind: %s\n",
          idx,
          item.label,
          entry:get_filter_text(),
          kind_string[item.kind]
        )
      )
      if item.data and item.data.imports and #item.data.imports > 0 then
        log:write(string.format("  data: %s\n", vim.inspect(item.data.imports[1])))
      end
    end
    log:close()
  end)
end

--- lsp.CompletionItemKind list, but in string.
M.CompletionItemKindString = {
  [1] = "Text",
  [2] = "Method",
  [3] = "Function",
  [4] = "Constructor",
  [5] = "Field",
  [6] = "Variable",
  [7] = "Class",
  [8] = "Interface",
  [9] = "Module",
  [10] = "Property",
  [11] = "Unit",
  [12] = "Value",
  [13] = "Enum",
  [14] = "Keyword",
  [15] = "Snippet",
  [16] = "Color",
  [17] = "File",
  [18] = "Reference",
  [19] = "Folder",
  [20] = "EnumMember",
  [21] = "Constant",
  [22] = "Struct",
  [23] = "Event",
  [24] = "Operator",
  [25] = "TypeParameter",
}

return M
