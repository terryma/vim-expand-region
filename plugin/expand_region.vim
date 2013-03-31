" ==============================================================================
" File: expand_region.vim
" Author: Terry Ma
" Description: Incrementally select larger regions of text in visual mode by
" repeating the same key combination
" Last Modified: March 30, 2013
" License: MIT license
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" ==============================================================================

let s:save_cpo = &cpo
set cpo&vim

" ==============================================================================
" Mappings
" ==============================================================================
if !hasmapto('<Plug>(expand_region_expand)')
  nmap + <Plug>(expand_region_expand)
  vmap + <Plug>(expand_region_expand)
endif
if !hasmapto('<Plug>(expand_region_shrink)')
  vmap _ <Plug>(expand_region_shrink)
  nmap _ <Plug>(expand_region_shrink)
endif
nnoremap <silent> <Plug>(expand_region_expand)
      \ :<C-U>call expand_region#next('n', '+')<CR>
vnoremap <silent> <Plug>(expand_region_expand)
      \ :<C-U>call expand_region#next('v', '+')<CR>
vnoremap <silent> <Plug>(expand_region_shrink)
      \ :<C-U>call expand_region#next('v', '-')<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
