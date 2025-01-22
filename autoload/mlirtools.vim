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
  let l:build_dir = l:current_dir . '/build/'
  return l:build_dir
endfunction

function! mlirtools#RunCommand(stage, build_dir, args) abort
  let l:args = a:args 
  let l:build_dir = mlirtools#GetBuildDir() . a:build_dir

  " Determine the error format based on the stage
  if a:stage ==# 'configure'
    let l:efm = mlirtools#GetConfigureErrorFormat()
    let l:cmd = 'cmake ' . ' ' . l:args
  elseif a:stage ==# 'build'
    let l:efm = mlirtools#GetBuildErrorFormat()
    let l:cmd = 'cmake --build ' . shellescape(l:build_dir) . ' ' . l:args
  elseif a:stage ==# 'test'
    let l:efm = mlirtools#GetCTestErrorFormat()
    let l:cmd = 'ctest --test-dir '. shellescape(l:build_dir) . ' ' . l:args
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

function! mlirtools#GetMLIRTestCommand()
  " Initialize variables
  let l:commands = []
  let l:current_cmd = ""
  let l:run_found = 0

  " Iterate through all lines in the buffer
  for l:line in getline(1, '$')
    " Check if the line starts with '// RUN:'
    if l:line =~ '^// RUN:'
      " Mark that we found a RUN line
      let l:run_found = 1

      " Remove the '// RUN: ' prefix
      let l:line = substitute(l:line, '^// RUN: ', '', '')

      " Check if the line ends with a backslash
      if l:line =~ '\\$'
        " Remove the backslash and add to the current command
        let l:current_cmd .= substitute(l:line, '\\$', '', '') . " "
      else
        " Add the complete line to the current command and finalize it
        let l:current_cmd .= l:line
        call add(l:commands, l:current_cmd)
        let l:current_cmd = ""
      endif
    elseif l:run_found
      " Break the loop if we've already found RUN lines and encounter a non-RUN line
      break
    endif
  endfor

  " Handle the case where the last line is incomplete
  if l:current_cmd != ""
    call add(l:commands, l:current_cmd)
  endif

  " Process each command
  let l:full_path = expand('%:p')
  for i in range(len(l:commands))
    " Remove FileCheck from command
    let l:commands[i] = substitute(l:commands[i], '|\s*FileCheck.*$', '', '')
    " Substitute %s with the full path of the current file
    let l:commands[i] = substitute(l:commands[i], '%s', l:full_path, 'g')
    " Trim leading or trailing whitespace
    let l:commands[i] = substitute(l:commands[i], '^\s*\(.\{-}\)\s*$', '\1', '')
  endfor

  " Join all commands into a single string, separated by semicolons
  return join(l:commands, " ; ")
endfunction
