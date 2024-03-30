---@meta

---@class RACompletionImport
---@field full_import_path string
---@field imported_name string

---@class RACompletionResolveData
---@field imports RACompletionImport[]
---@field position lsp.TextDocumentPositionParams

---@alias RAData RACompletionResolveData | nil
