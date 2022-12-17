# OpenTourBuilder
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/opentourbuilder/builder/Windows?label=Windows&style=for-the-badge)](https://github.com/opentourbuilder/builder/actions/workflows/windows.yml)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/opentourbuilder/builder/MacOS?label=MacOS&style=for-the-badge)](https://github.com/opentourbuilder/builder/actions/workflows/macos.yml)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/opentourbuilder/builder/Linux?label=Linux&style=for-the-badge)](https://github.com/opentourbuilder/builder/actions/workflows/linux.yml)

The OpenTourBuilder.

## Development setup
This application needs some files bundled alongside its executable. During development, these files
are put in a different place to reduce the burden on developers. On MacOS and Linux, this place is a
subdirectory of this one named `install`. On Windows, these files must be placed in
`C:\Users\%USERNAME%\AppData\Local\OpenTourBuilderDebugInstall`.

The required files are as follows:
- `geocodio.json` - A JSON file containing the Geocodio API key. The format is `{ "api_key": "<Geocodio API key>" }`.
- `lotyr/<Lotyr shared library name>` - The shared library for the Lotyr library for the current platform.
- `lotyr/valhalla.json` - A Valhalla configuration file that the tour builder will use to initialize Lotyr.
