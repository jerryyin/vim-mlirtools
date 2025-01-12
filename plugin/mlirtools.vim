if exists('g:loaded_mlirtools')
  finish
endif
let g:loaded_mlirtools = 1

let g:cmake_old_errorformat = &errorformat
let g:cmake_old_makeprg = &makeprg

command! -nargs=* CMakeConfigure call mlirtools#RunCommand('configure', <f-args>)
command! -nargs=* CMakeBuild call mlirtools#RunCommand('build', <f-args>)
command! -nargs=* CMakeTest call mlirtools#RunCommand('test', <f-args>)

command! -nargs=0 AGetMLIRTestCommand call mlirtools#GetMLIRTestCommand()
