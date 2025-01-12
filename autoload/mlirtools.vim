function! mlirtools#SetErrorFormat(efm) abort
  let &l:errorformat = a:efm
endfunction

function! mlirtools#RestoreErrorFormat() abort
  "let &l:errorformat = g:cmake_original_efm
  let &errorformat = g:cmake_old_errorformat
  let &makeprg = g:cmake_old_makeprg
endfunction

function! mlirtools#GetConfigureErrorFormat() abort
  return ' %#%f:%l %#(%m),'
    \ .'See also "%f".,'
    \ .'%E%>CMake Error at %f:%l:,'
    \ .'%Z  %m,'
    \ .'%E%>CMake Error at %f:%l (%[%^)]%#):,'
    \ .'%Z  %m,'
    \ .'%W%>Cmake Deprecation Warning at %f:%l (%[%^)]%#):,'
    \ .'%Z  %m,'
    \ .'%W%>Cmake Warning at %f:%l (%[%^)]%#):,'
    \ .'%Z  %m,'
    \ .'%E%>CMake Error: Error in cmake code at,'
    \ .'%C%>%f:%l:,'
    \ .'%Z%m,'
    \ .'%E%>CMake Error in %.%#:,'
    \ .'%C%>  %m,'
    \ .'%C%>,'
    \ .'%C%>    %f:%l (if),'
    \ .'%C%>,'
    \ .'%Z  %m,'
endfunction

function! mlirtools#GetBuildErrorFormat() abort
  return '%f:%l:%c: %trror: %m,'
    \ .'%.%#[1m%f:%l:%c: %.%#m%trror: %m,'
endfunction

function! mlirtools#GetCTestErrorFormat() abort
  return '%.%#at %f:%l offset :%.%#:%.%#: %trror: %m,'
    \ .'%f:%l:%c: %trror: %m,'
endfunction

function! mlirtools#GetBuildDir() abort
  " Define a pattern to locate the root directory
  let l:root_pattern = '.git'

  " Start from the current working directory
  let l:current_dir = getcwd()

  " Traverse up until the root directory is found
  while l:current_dir !=# '/' && !isdirectory(l:current_dir . '/' . l:root_pattern)
    let l:current_dir = fnamemodify(l:current_dir, ':h')
  endwhile

  " If no root directory is found, return '.'
  if l:current_dir ==# '/'
    return '.'
  endif

  " Check for the 'build' directory in the root directory
  let l:build_dir = l:current_dir . '/build'
  return l:build_dir
endfunction

function! mlirtools#RunCommand(stage, ...) abort
  let l:args = a:000
  let l:build_dir = mlirtools#GetBuildDir()

  " Determine the error format based on the stage
  if a:stage ==# 'configure'
    let l:efm = mlirtools#GetConfigureErrorFormat()
    let l:cmd = 'cmake ' . join(l:args)
  elseif a:stage ==# 'build'
    let l:efm = mlirtools#GetBuildErrorFormat()
    let l:cmd = 'cmake --build ' . shellescape(l:build_dir) . ' ' . join(l:args)
  elseif a:stage ==# 'test'
    let l:efm = mlirtools#GetCTestErrorFormat()
    let l:cmd = 'ctest --test-dir '. shellescape(l:build_dir) . ' ' . join(l:args)
  else
    echomsg 'Unknown stage: ' . a:stage
    return
  endif

  " Set the error format and make program
  call mlirtools#SetErrorFormat(l:efm)
  let &makeprg = l:cmd

  " Use :Make to run the command
  if exists(':Dispatch')
    silent! execute 'Make'
  else
    execute '!' . l:cmd
  endif

  call mlirtools#RestoreErrorFormat()
endfunction
