if exists('g:loaded_mlirtools')
  finish
endif
let g:loaded_mlirtools = 1

let g:cmake_old_errorformat = &errorformat
let g:cmake_old_makeprg = &makeprg

function! CMakeConfigure(build_dir, ...)
  call mlirtools#RunCommand('configure', a:build_dir, join(a:000))
endfunction

function! CMakeBuild(build_dir, ...)
  call mlirtools#RunCommand('build', a:build_dir, join(a:000))
endfunction

function! CMakeTest(build_dir, ...)
  call mlirtools#RunCommand('test', a:build_dir, join(a:000))
endfunction

function! GetMLIRTestCommand()
  return mlirtools#GetMLIRTestCommand()
endfunction
