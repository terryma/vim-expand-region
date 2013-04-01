" ==============================================================================
" File: expand_region.vim
" Author: Terry Ma
" Last Modified: March 30, 2013
" ==============================================================================

let s:save_cpo = &cpo
set cpo&vim

" ==============================================================================
" Settings
" ==============================================================================
if !exists('g:expand_region_text_objects')
  " Dictionary of text objects that are supported by default. Note that some of
  " the text objects are not available in vanilla vim. '1' indicates that the
  " text object is recursive (think of nested parens or brackets)
  let g:expand_region_text_objects = {
        \ 'iw'  :0,
        \ 'iW'  :0,
        \ 'i"'  :0,
        \ 'i''' :0,
        \ 'i]'  :1,
        \ 'ib'  :1,
        \ 'iB'  :1,
        \ 'il'  :0,
        \ 'ip'  :0,
        \ 'ie'  :0,
        \}
endif

" ==============================================================================
" Global Functions
" ==============================================================================

" Allow user to customize the global dictionary
function! expand_region#custom_text_objects(text_objects)
  call extend(g:expand_region_text_objects, a:text_objects)
endfunction

" Main function
function! expand_region#next(mode, direction)
  call s:expand_region(a:mode, a:direction)
endfunction

" ==============================================================================
" Variables
" ==============================================================================

" The saved cursor position when user initiates expand. This is the position we
" use to calcuate the region for all of our text objects. This is also used to
" restore the original cursor position when the region is completely shrinked.
let s:saved_pos = []

" Index into the list of filtered text objects(s:candidates), the text object
" this points to is the currently selected region.
let s:cur_index = -1

" The list of filtered text objects used to expand/shrink the visual selection.
" This is computed when expand-region is called the first time.
" Each item is a dictionary containing the following:
" text_object: The actual text object string
" start_pos: The result of getpos() on the starting position of the text object
" length: The number of characters for the text object
let s:candidates = []

" ==============================================================================
" Functions
" ==============================================================================

" Sort the text object by length in ascending order
function! s:sort_text_object(l, r)
  return a:l.length - a:r.length
endfunction

" Compare the relative positions of two text object regions. Return false if the
" rhs starts later in the buffer than the lhs.
function! s:compare_pos(l, r)
  if a:l[1] ==# a:r[1]
    " If number lines are the same, compare columns
    return a:l[2] - a:r[2] < 0 ? 0 : 1
  else
    return a:l[1] - a:r[1] < 0 ? 0 : 1
endfunction

" Remove duplicates from the candidate list. Two candidates are duplicates if
" they cover the exact same region (same length and same starting position)
function! s:remove_duplicate(input)
  let i = len(a:input) - 1
  while i >= 1
    if a:input[i].length ==# a:input[i-1].length &&
          \ a:input[i].start_pos ==# a:input[i-1].start_pos
      call remove(a:input, i)
    endif
    let i-=1
  endwhile
endfunction

" Return a single candidate dictionary. Each dictionary contains the following:
" text_object: The actual text object string
" start_pos: The result of getpos() on the starting position of the text object
" length: The number of characters for the text object
function! s:get_candidate_dict(text_object)
  " Store the current view so we can restore it at the end
  let winview = winsaveview()

  " Use ! as much as possible
  exec 'normal! v'
  exec 'silent! normal '.a:text_object
  " The double quote is important
  exec "normal! \<Esc>"

  let selection = s:get_visual_selection()
  let ret = {
        \ "text_object": a:text_object,
        \ "start_pos": selection.start_pos,
        \ "length": selection.length,
        \}

  " Restore peace
  call winrestview(winview)
  return ret
endfunction


" Return dictionary of text objects that are to be used for the current
" filetype. Filetype-specific dictionaries will be loaded if they exist
" and the global dictionary will be used as a fallback.
function! s:get_configuration()
  let configuration = {}
  for ft in split(&ft, '\.')
    if exists("g:expand_region_text_objects_".ft)
      call extend(configuration, g:expand_region_text_objects_{ft})
    endif
  endfor

  if empty(configuration)
    call extend(configuration, g:expand_region_text_objects)
  endif

  return configuration
endfunction

" Return list of candidate dictionary. Each dictionary contains the following:
" text_object: The actual text object string
" start_pos: The result of getpos() on the starting position of the text object
" length: The number of characters for the text object
function! s:get_candidate_list()
  " Turn off wrap to allow recursive search to work without triggering errors
  let save_wrapscan = &wrapscan
  set nowrapscan

  let config = s:get_configuration()

  " Generate the candidate list for every defined text object
  let candidates = keys(config)
  call map(candidates, "s:get_candidate_dict(v:val)")

  " For the ones that are recursive, generate them until they no longer match
  " any region
  let recursive_candidates = []
  for i in candidates
    " Continue if not recursive
    if !config[i.text_object]
      continue
    endif
    " If the first level is already empty, no point in going any further
    if i.length ==# 0
      continue
    endif
    let l:count = 2
    let previous = i.length
    while 1
      let test = l:count.i.text_object
      let candidate = s:get_candidate_dict(test)
      if candidate.length ==# 0
        break
      endif
      " If we're not producing larger regions, end early
      if candidate.length ==# previous
        break
      endif
      call add(recursive_candidates, candidate)
      let l:count+=1
      let previous = candidate.length
    endwhile
  endfor

  " Restore wrapscan
  let &wrapscan = save_wrapscan

  return extend(candidates, recursive_candidates)
endfunction

" Return a dictionary containing the start position and length of the current
" visual selection.
function! s:get_visual_selection()
  let start_pos = getpos("'<")
  let [lnum1, col1] = start_pos[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  return {
        \ 'start_pos': start_pos,
        \ 'length': len(join(lines, "\n"))
        \}
endfunction

" Figure out whether we should compute the candidate text objects, or we're in
" the middle of an expand/shrink.
function! s:should_compute_candidates(mode)
  if a:mode ==# 'v'
    " Check that current visual selection is idential to our last expanded
    " region
    if s:cur_index >= 0
      let selection = s:get_visual_selection()
      if s:candidates[s:cur_index].start_pos ==# selection.start_pos
            \ && s:candidates[s:cur_index].length ==# selection.length
        return 0
      endif
    endif
  endif
  return 1
endfunction

" Computes the list of text object candidates to be used given the current
" cursor position.
function! s:compute_candidates(cursor_pos)
  " Reset index into the candidates list
  let s:cur_index = -1

  " Save the current cursor position so we can restore it later
  let s:saved_pos = a:cursor_pos

  " Compute a list of candidate regions
  let s:candidates = s:get_candidate_list()

  " Sort them and remove the ones with 0 or 1 length
  call filter(sort(s:candidates, "s:sort_text_object"), 'v:val.length > 1')

  " Filter out the ones where the start of the text object is after the cursor
  " position, i", and i' can cause this
  call filter(s:candidates, 's:compare_pos(s:saved_pos, v:val.start_pos)')

  " Remove duplicates
  call s:remove_duplicate(s:candidates)
endfunction

" Expand or shrink the visual selection to the next candidate in the text object
" list.
function! s:expand_region(mode, direction)
  if s:should_compute_candidates(a:mode)
    call s:compute_candidates(getpos('.'))
  else
    call setpos('.', s:saved_pos)
  endif

  if a:direction ==# '+'
    " Expanding
    if s:cur_index ==# len(s:candidates) - 1
      normal! gv
    else
      let s:cur_index+=1
      " Associate the window view with the text object
      let s:candidates[s:cur_index].prev_winview = winsaveview()
      exec 'normal! v'
      exec 'normal '.s:candidates[s:cur_index].text_object
    endif
  else
    "Shrinking
    if s:cur_index <=# 0
      " Do nothing, this will also return us to normal mode
    else
      let s:cur_index-=1
      " Restore the window view
      call winrestview(s:candidates[s:cur_index].prev_winview)
      exec 'normal! v'
      exec 'normal '.s:candidates[s:cur_index].text_object
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
