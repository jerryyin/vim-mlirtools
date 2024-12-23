# CMake Plugin for Vim

This plugin integrates CMake functionality into Vim, providing commands to configure, build, and test projects, with stage-specific error formats for better error handling.

## Features

- Configure projects with `CMakeConfigure`.
- Build targets with `CMakeBuild`.
- Run tests with `CMakeTest`.
- Stage-specific error formats:
  - CMake configuration errors and warnings.
  - Compiler errors and warnings.
  - CTest failure messages.

## Usage

Configure a project:
> :CMakeConfigure -B build -DCMAKE_BUILD_TYPE=Debug

Build a target:
> :CMakeBuild --target my_target

Run tests:
> :CMakeTest -R my_test
