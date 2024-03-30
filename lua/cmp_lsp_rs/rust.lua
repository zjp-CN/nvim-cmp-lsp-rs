local M = {}

M.inscope_inherent = require("cmp_lsp_rs.rust.inscope_inherent").inscope_inherent
M.inscope_inherent_import = require("cmp_lsp_rs.rust.inscope_inherent_import").inscope_inherent_import

M.inherent_import_inscope = require("cmp_lsp_rs.rust.inherent_import_inscope").inherent_import_inscope

return M
