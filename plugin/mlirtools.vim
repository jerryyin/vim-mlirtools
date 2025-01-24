if exists('g:loaded_mlirtools')
  finish
endif
let g:loaded_mlirtools = 1

let g:cmake_old_errorformat = &errorformat
let g:cmake_old_makeprg = &makeprg
let g:cmake_build_dir = ''

command! -nargs=1 CmakeSetDir call mlirtools#SetBuildDir(<f-args>)
command! -nargs=* CMakeConfigure call mlirtools#RunCommand('configure', <f-args>)
command! -nargs=* CMakeBuild call mlirtools#RunCommand('build', <f-args>)
command! -nargs=* CMakeTest call mlirtools#RunCommand('test', <f-args>)

function! GetMLIRTestCommand()
  return mlirtools#GetMLIRTestCommand()
endfunction
