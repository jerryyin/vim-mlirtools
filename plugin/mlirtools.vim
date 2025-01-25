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

"let s:plugin_root_dir = expand('<sfile>:p:h:h')

"python3 << EOF
"import sys
"from os.path import normpath, join
"import vim
"plugin_root_dir = vim.eval('s:plugin_root_dir')
"python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
"sys.path.insert(0, python_root_dir)
"import generate_test_checks
"EOF
"
"function! mlirtools#ProcessMLIR(input) abort
"  return py3eval("generate_test_checks.generate_checks_from_string(" . string(a:input) . ")")
"endfunction

function! GenerateTestChecks(cmd_type)
  call mlirtools#GenerateTestChecks(a:cmd_type)
endfunction

function! RunToScratch(cmd)
  call mlirtools#RunToScratch(a:cmd)
endfunction

