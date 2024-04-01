---@meta

---@class cmp_lsp_rs.RACompletionImport
---@field full_import_path string
---@field imported_name string

---@class cmp_lsp_rs.RACompletionResolveData
---@field imports cmp_lsp_rs.RACompletionImport[]
---@field position lsp.TextDocumentPositionParams

---@alias cmp_lsp_rs.RAData cmp_lsp_rs.RACompletionResolveData | nil

---@class cmp_lsp_rs.CompletionItemKind
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

---A handy way to write the CompletionItemKind from the argument.
---@alias cmp_lsp_rs.KindSelect fun(kind: cmp_lsp_rs.CompletionItemKind): lsp.CompletionItemKind[]

---A kind or a list of kind name.
---@alias cmp_lsp_rs.KindNames string[] | string

---A kind or a list of kind.
---@alias cmp_lsp_rs.Kinds lsp.CompletionItemKind[] | lsp.CompletionItemKind

---@alias cmp_lsp_rs.ComparatorFunction cmp.ComparatorFunction[] | fun(): cmp.ComparatorFunction[]

---@alias cmp_lsp_rs.Combo table<string,  cmp_lsp_rs.ComparatorFunction>

---@class cmp_lsp_rs.Opts
---@field kind? cmp_lsp_rs.Kinds | cmp_lsp_rs.KindSelect make these kinds prior to others
---@field unwanted_prefix? string[] filter out import items starting with the prefixes
---@field combo? cmp_lsp_rs.Combo combinations of comparators
