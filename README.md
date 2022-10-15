# Evresi Tour Builder
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/evresi/builder/Windows?label=Windows&style=for-the-badge)](https://github.com/evresi/builder/actions/workflows/windows.yml)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/evresi/builder/MacOS?label=MacOS&style=for-the-badge)](https://github.com/evresi/builder/actions/workflows/macos.yml)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/evresi/builder/Linux?label=Linux&style=for-the-badge)](https://github.com/evresi/builder/actions/workflows/linux.yml)

The Evresi tour builder.

## Note for development
The tour builder needs some files bundled alongside its executable. On MacOS and Linux, these files
can be placed in a subdirectory of this directory named `install`. On Windows, these files must be
placed in `C:\Users\%USERNAME%\AppData\Local\EvresiBuilderDebugInstall`.
