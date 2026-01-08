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

" Function to set the build directory
function! mlirtools#SetBuildDir(build_dir) abort
  if !isdirectory(a:build_dir)
    echomsg 'The specified build directory does not exist: ' . a:build_dir
    return
  endif
  let g:cmake_target_dir = a:build_dir
  echomsg 'Build directory set to: ' . g:cmake_target_dir
endfunction

function! mlirtools#GetRootDir() abort
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

  return l:current_dir
endfunction

" Function to get the build directory
function! mlirtools#GetTargetDir() abort
  " Use the globally set build directory if available
  if g:cmake_target_dir !=# ''
    return g:cmake_target_dir
  endif

  let l:root_dir = mlirtools#GetRootDir()
  let l:build_base = l:root_dir . '/build'

  " Check if the base build directory exists
  if isdirectory(l:build_base)
    " If there are multiple subdirectories, pick the one that
    " compile_commands.json pointed to from build/compiler_commands.json
    let l:compile_commands = l:build_base . '/compile_commands.json'
    if filereadable(l:compile_commands)
      let l:link_target = resolve(l:compile_commands)
      let l:compile_commands_dir = fnamemodify(l:link_target, ':h')
      return l:compile_commands_dir
    endif
  endif

  " Fallback to the default directory
  errmesg 'No build directory found. Using build/dbg directory.'
  let l:default_build_dir = l:build_base . '/dbg'
  return l:default_build_dir
endfunction

function! mlirtools#SetupClangdSymlink() abort
  let l:root_dir = mlirtools#GetRootDir()
  let l:build_dir = l:root_dir . '/build'
  let l:symlink_source = l:build_dir . '/compile_commands.json'

  let l:target_dir = mlirtools#GetTargetDir()
  let l:symlink_target = l:target_dir . '/compile_commands.json'

  echom l:symlink_source . ' -> ' . l:symlink_target

  " Note: target may not exist when executing since it is async command
  call system('ln -sf ' . l:symlink_target . ' ' . l:symlink_source)
endfunction

" The preset function would create a directory using the preset name under The
" build repository and then run the preset command in that directory.
function! mlirtools#RunPreset(preset_name, ...)
  let l:args = a:000
  let l:root_dir = mlirtools#GetRootDir()
  let l:build_dir = l:root_dir . '/build'
  let l:preset_dir = l:build_dir . '/' . a:preset_name
  let g:cmake_target_dir = l:preset_dir

  " Create the preset directory if it doesn't exist
  if !isdirectory(l:preset_dir)
    call mkdir(l:preset_dir, 'p')
  endif

  " Run the command in the preset directory
  call mlirtools#RunCommand('configure', '--preset ', a:preset_name, join(l:args))

  call mlirtools#SetupClangdSymlink()
endfunction

function! mlirtools#RunCommand(stage, ...) abort
  let l:args = a:000
  let l:target_dir = mlirtools#GetTargetDir()

  " Determine the error format based on the stage
  if a:stage ==# 'configure'
    let l:efm = mlirtools#GetConfigureErrorFormat()
    let l:cmd = 'cmake ' . join(l:args)
  elseif a:stage ==# 'build'
    let l:efm = mlirtools#GetBuildErrorFormat()
    let l:cmd = 'cmake --build ' . shellescape(l:target_dir) . ' ' . join(l:args)
  elseif a:stage ==# 'test'
    let l:efm = mlirtools#GetCTestErrorFormat()
    let l:cmd = 'ctest --test-dir '. shellescape(l:target_dir) . ' ' . join(l:args)
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

function! mlirtools#RunToScratch(cmd) abort
  " Open a new vertical split for the scratch buffer
  vertical new
  setlocal buftype=nofile bufhidden=wipe noswapfile
  let l:bufnr = bufnr('%')

  " stdout callback
  function! s:OnStdout(chan, msg) dict
    if bufexists(self.bufnr) && a:msg !=# ''
      let l:lines = split(a:msg, '\n')
      " Append at the end of buffer
      call appendbufline(self.bufnr, '$', l:lines)
    endif
  endfunction

  " stderr callback
  function! s:OnStderr(chan, msg) dict
    if bufexists(self.bufnr) && a:msg !=# ''
      let l:lines = split(a:msg, '\n')
      call appendbufline(self.bufnr, '$', l:lines)
    endif
  endfunction

  " close callback
  function! s:OnClose(chan) dict
    if bufexists(self.bufnr)
      call appendbufline(self.bufnr, '$', ['--- job finished ---'])
    endif
  endfunction

  " Start async job - wrap in shell to handle &&, ;, pipes, etc.
  call job_start(['/bin/sh', '-c', a:cmd], {
        \ 'out_cb':   function('s:OnStdout', {'bufnr': l:bufnr}),
        \ 'err_cb':   function('s:OnStderr', {'bufnr': l:bufnr}),
        \ 'close_cb': function('s:OnClose',  {'bufnr': l:bufnr}),
        \ })
endfunction

let s:plugin_root_dir = expand('<sfile>:p:h:h')
function! mlirtools#GenerateTestChecks(cmd_type)
  let l:plugin_dir = s:plugin_root_dir
  let l:script_path = l:plugin_dir . '/python/generate_test_checks.py'
  let l:buffer_content = join(getline(1, '$'), "\n")

  if a:cmd_type == 'buffer'
    let l:cmd = 'echo '.shellescape(l:buffer_content).' | python '.shellescape(l:script_path).' -'
  elseif a:cmd_type == 'file'
    let l:buffer_path = expand('%:p')
    let l:cmd = GetMLIRTestCommand(). ' | python '.shellescape(l:script_path).' --source '.shellescape(l:buffer_path)
    "let l:cmd = '('. GetMLIRTestCommand(). ') | python -O '.shellescape(l:script_path).' --source '.shellescape(l:buffer_path)
  else
    echohl ErrorMsg
    echo "Invalid command type. Use 'buffer' or 'file'."
    echohl None
    return
  endif

  call RunToScratch(l:cmd)
endfunction

