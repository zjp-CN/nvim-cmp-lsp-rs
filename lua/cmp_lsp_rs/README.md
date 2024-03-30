## nvim-cmp-lsp-rs

Refine completion behavior by applying useful filtering and sorting for candidates,
but only specific to Rust filetype (or rather Rust-Analyzer).


Experience before:
[![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/e3b00e5e-7aa2-4a46-8704-7351f24d7ded)][#1]

[#1]: https://github.com/zjp-CN/nvim-cmp-lsp-rs/issues/1

and after:

![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/f69d8ec9-8611-4a0a-a4ef-b0e8f38ac8c1)

![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/83bda386-a5e8-4040-ae7f-56cd9501da4f)
### Background

Have you bee aware of the great [comparators][cmp-comparators] in [nvim-cmp]?

[nvim-cmp]: https://github.com/hrsh7th/nvim-cmp/tree/main
[cmp-comparators]: https://github.com/hrsh7th/nvim-cmp/blob/97dc716fc914c46577a4f254035ebef1aa72558a/lua/cmp/config/compare.lua

The default sorting is defined as below, which means if you use [`LazyVim`], you'll see the
weird completion item list exactly as the first picture show.

[`LazyVim`]: https://www.lazyvim.org/

```lua
sorting = {
  priority_weight = 2,
  comparators = {
    compare.offset,
    compare.exact,
    -- compare.scopes,
    compare.score,
    compare.recently_used,
    compare.locality,
    compare.kind,
    -- compare.sort_text,
    compare.length,
    compare.order,
  },
}
```

The problem is not about each sorting, but about the combination of sortings.

`compare.kind` is very close to the end, meaning it'll be used only if all the sortings 
before it return nil.

A comparator is a sorting function [used] in `table.sort` to compare two arguments passed in.

A comparator in the form of `fn(a, b)` returns
* true to indicate a is prior to b 
* false to indicate b is prior to a 
* nil to indicate comparison result is the same or uncertain: like for the same lsp.CompletionItemKind

[used]: https://github.com/hrsh7th/nvim-cmp/blob/97dc716fc914c46577a4f254035ebef1aa72558a/lua/cmp/view.lua#L64

So if you want a simplist and general solution, putting `require("cmp").config.compare.kind` first might be good.
It sort the completion items in [completionItemKind] order, but with Text kind lowest priority and Snippet kind 
a bit higher in some cases. 

[completionItemKind]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItemKind

You may notice sometimes the ordering is not good for Rust codebases!
* You don't want Snippets have higher priorities: search in RA's [manual] with `snippet` keyword, and there are 
  many cool features to let you config/add these Snippets.
  * But if you've already used [LuaSnip] (or a snippet User UI [nvim-scissors]), too much for Snippets!
* You want some kinds to be higher priorities: [CompletionItemKind] treats Variables and Fields lower then Methods, 
  then you can do nothing but typing more to wait the desired one pops up.
  * Typing more is not a big problem: when you have large candidates, no matter for what sorting, you must type more 
    characters or arrow keys :)
  * The bigger problem is kinds like Variables/Fields are closer to use for you compared to other kinds.
* You want features sepecific to Rust. Like
  * Items in scope are prior to that needing to import.
    * You may rarely want a non-imported method appears as the first candidate when other in-scope methods exist.
    * You may want local modules prior to external modules.
  * Inherent methods are prior to trait methods.

[manual]: https://rust-analyzer.github.io/manual.html
[LuaSnip]: https://github.com/L3MON4D3/LuaSnip
[nvim-scissors]: https://github.com/chrisgrieser/nvim-scissors

Why are you telling me this story or details?
* I didn't realize nvim-cmp could change the sorting behavior so much easily even though I've been using it 
  for two years in (almost) daily coding.
* I encourage you to check out the comparators, tweak it a bit so that feel comfortable when seeing completion popup.
* Then enjoy the wonderful completion experience neovim and nvim-cmp power us with or without this plugin.
   * I don't want to extend the sorting functions to other LSP/languanges.
     Plus, I'm really poor in writing Lua scripts (and coding). So forgive me for no vim-doc at the moment.

### Usage

TODO
