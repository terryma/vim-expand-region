# vim-expand-region

## About
[vim-expand-region] is a Vim plugin that allows you to visually select increasingly larger regions of text using the same key combination. It is similar to features from other editors:

- Emac's [expand region](https://github.com/magnars/expand-region.el)
- IntelliJ's [syntax aware selection](http://www.jetbrains.com/idea/documentation/tips/#tips_code_editing)
- Eclipse's [select enclosing element](http://stackoverflow.com/questions/4264047/intellij-ctrlw-equivalent-shortcut-in-eclipse)

<p align="center">
  <img src="https://raw.github.com/terryma/vim-expand-region/master/expand-region.gif" alt="vim-expand-region" />
</p>

## Installation
Install using [Pathogen], [Vundle], [Neobundle], or your favorite Vim package manager.

## Quick Start
Press ```+``` to expand the visual selection and ```_``` to shrink it.

## Mapping
Customize the key mapping if you don't like the default.

```
map K <Plug>(expand_region_expand)
map J <Plug>(expand_region_shrink)
```

## Setting
The plugin uses __your own__ text objects to determine the expansion. You can customize the text objects the plugin knows about with ```g:expand_region_text_objects```.

```vim
" Default
let g:expand_region_text_objects = {
  'iw'  :0,
  'iW'  :1,
  'i"'  :0,
  'i''' :0,
  'i]'  :1, " Support nesting of square brackets
  'ib'  :1, " Support nesting of parentheses
  'iB'  :1, " Support nesting of braces
  'il'  :0, " 'inside line'. Not included in Vim by default. See https://github.com/kana/vim-textobj-line
  'ip'  :0,
  'ie'  :0  " 'entire file'. Not included in Vim by default. See https://github.com/kana/vim-textobj-entire
}
```

Replace it completely or extend the default by putting the following in your vimrc:

```vim
" Extend the text object dictionary (NOTE: Remove comments in dictionary before sourcing)
call expand_region#custom_text_objects({
      \ "\/\\n\\n\<CR>": 1, " If you're really crazy, you could supply search patterns. They're also text objects.
      \ 'a]'  :1, " Support nesting of 'around' brackets
      \ 'ab'  :1, " Support nesting of 'around' parentheses
      \ 'aB'  :1, " Support nesting of 'around' braces
      \ 'ii'  :0, " 'inside indent'. Not included in Vim by default. See https://github.com/kana/vim-textobj-indent
      \ 'ai'  :0, " 'around indent'. Not included in Vim by default. See https://github.com/kana/vim-textobj-indent
      \})
```

[vim-expand-region]:http://github.com/terryma/vim-expand-region
[Pathogen]:http://github.com/tpope/vim-pathogen
[Vundle]:http://github.com/gmarik/vundle
[Neobundle]:http://github.com/Shougo/neobundle.vim
