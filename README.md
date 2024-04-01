## nvim-cmp-lsp-rs

Refine completion behavior by applying useful filtering and sorting for candidates,
but only specific to Rust filetype (or rather Rust-Analyzer).


Before (click the picture and jump to #1 to see details)
[![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/e3b00e5e-7aa2-4a46-8704-7351f24d7ded)][#1]

[#1]: https://github.com/zjp-CN/nvim-cmp-lsp-rs/issues/1

and after (both are improved, which is better depends on your usecase!)

![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/f69d8ec9-8611-4a0a-a4ef-b0e8f38ac8c1)

![](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/83bda386-a5e8-4040-ae7f-56cd9501da4f)

One of the improvements is alphabetic sortings separately on inherent methods,
in-scope trait methods and to-be-imported trait methods.

For more usage, jump to [Usage](#usage) section by skipping mutters in Background.


<details>

<summary>Background</summary>

Have you been aware of the great [comparators][cmp-comparators] in [nvim-cmp]?

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

`compare.kind` is very close to the tail, meaning it'll be used only if all the sortings 
before it return nil.

A comparator is a sorting function [used] in `table.sort` to compare two arguments passed in.

A comparator in the form of `fn(a, b)` returns
* true to indicate a is prior to b 
* false to indicate b is prior to a 
* nil to indicate comparison result is the same or uncertain: like for the same lsp.CompletionItemKind

[used]: https://github.com/hrsh7th/nvim-cmp/blob/97dc716fc914c46577a4f254035ebef1aa72558a/lua/cmp/view.lua#L64

So if you want a simplist and general solution, putting `require("cmp").config.compare.kind` first might be good.
It sort the completion items in [completionItemKind] order, but with Text kind always lowest priority and Snippet
kind a bit higher in some cases. 

[completionItemKind]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItemKind

You may notice sometimes the ordering is not good for Rust codebases!
* You don't want Snippets have higher priorities: search in RA's [manual] with `snippet` keyword, and there are 
  many cool features to let you config/add these Snippets.
  * But if you've already used [LuaSnip] (or snippets edit User UI [nvim-scissors]), too much for Snippets kind!
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
* Share what I found lately. I didn't realize nvim-cmp could change the sorting behavior so much easily
  even though I've been using it for two years in (almost) daily coding.
* Encourage you to check out the comparators, tweak it a bit so that feel comfortable when seeing completion popup.
* Knowing more details helps you use or write related code to enjoy the wonderful completion experience
  neovim and nvim-cmp power us.
* I don't want to extend the sorting functions to other LSP/languanges. So the background hopefully can
  inspire people starting out.

</details>

### Usage

This plugin should be a plugin of `nvim-cmp`, which means the completion 
behavior is affacted by specifying `sorting.comparators` and `entry_filter`
in nvim-cmp.

Here's how to do in lazy.nvim (NOT default setting)
```lua
  {
    "hrsh7th/nvim-cmp",
    keys = {
        -- See opts.combo from nvim-cmp-lsp-rs below
        {
          "<leader>bc",
          "<cmd>lua require'cmp_lsp_rs'.combo()<cr>",
          desc = "(nvim-cmp) switch comparators"
        },
    },
    dependencies = {
      {
        "zjp-CN/nvim-cmp-lsp-rs",
        ---@type cmp_lsp_rs.Opts
        opts = {
          -- Filter out import items starting with one of these prefixes.
          -- A prefix can be crate name, module name or anything an import 
          -- path starts with, no matter it's complete or incomplete.
          -- Only literals are recognized: no regex matching.
          unwanted_prefix = { "color", "ratatui::style::Styled" },
          -- make these kinds prior to others
          -- e.g. make Module kind first, and then Function second,
          --      the rest ordering is merged from a default kind list
          kind = function(k) 
            -- The argument in callback is type-aware with opts annotated,
            -- so you can type the CompletionKind easily.
            return { k.Module, k.Function }
          end,
          -- Override the default comparator list provided by this plugin.
          -- Mainly used with key binding to switch between these Comparators.
          combo = {
            -- The key is the name for combination of comparators and used 
            -- in notification in swiching.
            -- The value is a list of comparators functions or a function 
            -- to generate the list.
            alphabetic_label_but_underscore_last = function()
              local comparators = require("cmp_lsp_rs").comparators
              return { comparators.sort_by_label_but_underscore_last }
            end,
            recentlyUsed_sortText = function()
              local compare = require("cmp").config.compare
              local comparators = require("cmp_lsp_rs").comparators
              -- Mix cmp sorting function with cmp_lsp_rs.
              return {
                compare.recently_used,
                compare.sort_text,
                comparators.sort_by_label_but_underscore_last
              }
            end,
          },
        },
      },
    },
    --@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp_lsp_rs = require("cmp_lsp_rs")
      local comparators = cmp_lsp_rs.comparators

      opts.sorting.comparators = {
        -- comparators.inherent_import_inscope,
        comparators.inscope_inherent_import,
        comparators.sort_by_label_but_underscore_last,
      }

      for _, source in ipairs(opts.sources) do
        cmp_lsp_rs.filter_out.entry_filter(source)
      end

      return opts
    end,
  }
```
`unwanted_prefix` only applies to import items, with items in scope unaffacted.

When specifying the kind list, you can directly pass in a list of integer that 
`lsp.CompletionItemKind` represents. So `kind = { 9, 3 }` behaves the same way.

It's totally fine to omit opts on nvim-cmp-lsp-rs, and dynamically 
change them in runtime when you already open a rust file and RA starts.

The way to inject into nvim-cmp's config is by overriding comparators list 
and entry_filter for nvim_lsp source.

NOTE: we use a callback to modify opts on nvim-cmp, because opts table form 
can't make this plugin work. Maybe this is a nuance from lazy.nvim. Therefore,
you should tweak your original opts to this way.

The order in comparators list matters. `inscope_inherent_import` or 
`inherent_import_inscope` is used with `kind`. They will sort Rust entries
by kind, and then group for inherent vs trait methods and in-scope vs import 
items. They will also affact non-Rust entries, but only sort them by kind. 

`sort_by_label_but_underscore_last` will sort the entries the first comparator 
emits nil on. The sort is alphabetic, but `_` will be put to the last. This 
is most desired because it means low priority in most cases. If you don't want 
`_` to be last, use `sort_by_kind` instead.

The entry_filter will only apply to nvim_lsp source and rust filetype.
Currently, it filters out import methods with unwanted_prefix.

### cmp_lsp_rs.comparators

Two sorting functions are provided.

#### inscope_inherent_import

```lua
 local cmp_rs = require("cmp_lsp_rs")
 local comparators = cmp_rs.comparators
 
 opts.sorting.comparators = {
   comparators.inscope_inherent_import,
   comparators.sort_by_label_but_underscore_last,
 }
```
Sorting Behaviors:

* in-scope items
  * kind order: Field -> Method -> rest
    * alphabetic sort on item names separately in the same kind
  * method order: inherent -> trait
    * alphabetic sort on method names in inherent
    * alphabetic sort on trait names in trait methods
    * alphabetic sort on method names in the same trait
* import items
  * kind order
    * alphabetic sort on item names separately in the same kind
  * trait method order
    * alphabetic sort on trait names in trait methods
    * alphabetic sort on method names in the same trait
```rust
 [entry 1] s (this is a Field)
 [entry 2] render(…)
 [entry 3] zzzz()
 [entry 4] f() (as AAA)
 [entry 5] z() (as AAA)
 [entry 6] into() (as Into)
 [entry 7] try_into() (as TryInto)
 ... other kinds
 [entry 24] bg() (use color_eyre::owo_colors::OwoColorize)
 ... methods from color_eyre::owo_colors::OwoColorize trait
 [entry 79] yellow() (use color_eyre::owo_colors::OwoColorize)
 [entry 80] type_id() (use std::any::Any)
 [entry 81] borrow() (use std::borrow::Borrow)
 [entry 82] borrow_mut() (use std::borrow::BorrowMut)
 ... other kinds
```

### inherent_import_inscope

```lua
  local cmp_rs = require("cmp_lsp_rs")
  local comparators = cmp_rs.comparators
  
  opts.sorting.comparators = {
    comparators.inherent_import_inscope,
    comparators.sort_by_label_but_underscore_last,
  }
```
Sorting Behaviors:

* kind order: Field -> Method -> rest
  * alphabetic sort on item names separately in the same kind
  * method order
    * inherent methods
      * alphabetic sort on method names
    * trait methods
      * in-scope methods
        * alphabetic sort on trait names in trait methods
        * alphabetic sort on method names in the same trait
      * import methods
          * alphabetic sort on trait names in trait methods
          * alphabetic sort on method names in the same trait
```rust
  [entry 1] s (this is a Field)
  [entry 2] render(…)
  [entry 3] zzzz()
  [entry 4] f() (as AAA)
  [entry 5] z() (as AAA)
  [entry 6] into() (as Into)
  [entry 7] try_into() (as TryInto)
  [entry 8] bg() (use color_eyre::owo_colors::OwoColorize)
  ... (use color_eyre::owo_colors::OwoColorize)
  [entry 63] yellow() (use color_eyre::owo_colors::OwoColorize)
  [entry 64] type_id() (use std::any::Any)
  [entry 65] borrow() (use std::borrow::Borrow)
  [entry 66] borrow_mut() (use std::borrow::BorrowMut)
  ... 
```

### cmp_lsp_rs.combo

See the configuration exampl in [usage](#usage) above.

You can bind the function to a key to switch between defined combinations.

The default is like
```lua
  {
    ["inherent_import_inscope + sort_by_label"] = {
      M.comparators.inherent_import_inscope, 
      M.comparators.sort_by_label
    },
    ["inscope_inherent_import + sort_by_label"] = {
      M.comparators.inscope_inherent_import,
      M.comparators.sort_by_label
    },
  }
```

![toggle-combo](https://github.com/zjp-CN/nvim-cmp-lsp-rs/assets/25300418/ec77123b-0cc4-422b-9557-774d544ed57a)

### cmp_lsp_rs.log

You can call `require("cmp_lsp_rs").log.register()` to listen on `menu_opened`
event emitted by nvim-cmp to obtain the last and sorted completion result 
displayed to you.

The log file is `entries.log` right under the current folder.

This is mainly used in debuging. 

<details>

<summary>The format shouldn't be relied on. e.g.</summary>

```rust
  [entry 1] s
    filter_text: s
    kind: Field
  [entry 2] render(…)
    filter_text: render
    kind: Method
  [entry 3] zzzz()
    filter_text: zzzz
    kind: Method
  [entry 4] f() (as AAA)
    filter_text: f
    kind: Method
    [entry 5] z() (as AAA)
    filter_text: z
    kind: Method
  [entry 6] into() (as Into)
    filter_text: into
    kind: Method
  [entry 8] box
    filter_text: box
    kind: Snippet
  [entry 80] type_id() (use std::any::Any)
    filter_text: type_id
    kind: Method
    data: {
    full_import_path = "std::any::Any",
    imported_name = "Any"
  }
  [entry 84] arc (use std::sync::Arc)
    filter_text: arc
    kind: Snippet
    data: {
    full_import_path = "std::sync::Arc",
    imported_name = "Arc"
  }
```
</details>

### Dynamic Setting in Runtime

The filtering and sorting in nvim-cmp are pretty dynamic and straightforward.

Each entry from various sources will be passed into `entry_filter` which a 
function accepts and returns if it returns true. Then a table of entries will
be sorted by a list of comparator.

#### Dynamic Unwanted Prefix
```vim
  :lua rs = require'cmp_lsp_rs'
  :lua rs.unwanted_prefix.get()    -- query
  :lua rs.unwanted_prefix.set(...) -- override
  :lua rs.unwanted_prefix.add(...) -- append
  :lua rs.unwanted_prefix.remove(...) -- delete
```
The argument `{...}` for them can be a `string` or `string[]`.
Default to empty.

#### Dynamic Kind Sorting

```vim
  :lua rs = require'cmp_lsp_rs'
  :lua rs.kind.get()    -- query
  :lua rs.kind.set(...) -- set kind ordering with most priorities
```
The argument `...` for `set` can be one of these 
* `string` name for kind
* `string[]` names for kind
* `integer` integer for kind
* `integer[]` integers for kind
* `function(k) -> integer[]` where k is of kind type and you can easily write 
  the kinds like `k.Module` etc with lsp help. 

e.g. for the last case, you can write 
```lua
  rs.kind.set(function(k) return { k.Module, k.Function })
```

The current default ordering is as follows:
```
  Variable Value Field EnumMember Property TypeParameter Method Module
  Function Constructor Interface Class Struct Enum Constant Unit Keyword
  Snippet Color File Folder Event Operator Reference Text 
```

#### Dynamic Comparators

If you want to override comparators nvim-cmp calls when experimenting them,
you can run these commands.
```vim
  :lua rs = require'cmp_lsp_rs'
  :lua cmp = require'cmp'
  :lua cmp.get_config().sorting.comparators = { rs.comparators.sort_by_label }
```


