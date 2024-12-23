if exists('g:loaded_cmake')
  finish
endif
let g:loaded_cmake = 1

let g:cmake_old_errorformat = &errorformat
let g:cmake_old_makeprg = &makeprg

command! -nargs=* CMakeConfigure call cmake#RunCommand('configure', <f-args>)
command! -nargs=* CMakeBuild call cmake#RunCommand('build', <f-args>)
command! -nargs=* CMakeTest call cmake#RunCommand('test', <f-args>)

