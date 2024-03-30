---@meta

---@class RACompletionImport
---@field full_import_path string
---@field imported_name string

---@class RACompletionResolveData
---@field imports RACompletionImport[]
---@field position lsp.TextDocumentPositionParams

---@alias RAData RACompletionResolveData | nil

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
