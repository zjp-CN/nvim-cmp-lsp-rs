local M = {}
local rust = require("cmp_lsp_rs.rust")

M.sort_by_kind = require("cmp_lsp_rs.sort_by_kind").sort_by_kind

M.sort_by_label = require("cmp_lsp_rs.sort_by_label").sort_by_label

M.sort_by_label_but_underscore_last = require("cmp_lsp_rs.sort_by_label").sort_by_label_but_underscore_last
M.sort_by_label_but_underscore_nil = require("cmp_lsp_rs.sort_by_label").sort_by_label_but_underscore_nil
M.sort_underscore = require("cmp_lsp_rs.sort_by_label").sort_underscore

M.inherent_import_inscope = rust.inherent_import_inscope
M.inscope_inherent = rust.inscope_inherent
M.inscope_inherent_import = rust.inscope_inherent_import

return M
