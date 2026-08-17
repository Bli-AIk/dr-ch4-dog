# dr-ch4-dog

[![license](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue)](LICENSE-APACHE)

**dr-ch4-dog** is a standard Lua Kristal template. It keeps a playable starter map, Dummy battle, and object event while wiring together Simplified Chinese localization, development-only object editing and terminal debugging, and project-local Emacs and Helix configuration.

[简体中文](README.md)

## Quick Start

    git clone --recurse-submodules https://github.com/Bli-AIk/dr-ch4-dog.git
    cd dr-ch4-dog
    git submodule update --init --recursive
    make test
    KRISTAL_ROOT=/path/to/Kristal just run

Battle startup debugging is provided by the `kristal-debug-tools` library submodule:

    just run --encounter
    just run --wave 2 --tp 50 --mercy 100
    just run --wave-force 3

The template uses dr-ch4-dog as its Mod ID. Change the ID, display name, version, and README badge URLs after creating a repository from the GitHub template.

## Tooling

- Kristal and LÖVE 11.5 for local runs and standalone builds.
- LuaJIT for syntax checks and runtime support.
- kristal-i18n for English and Simplified Chinese localization.
- kristal-object-selector-plus for development-only scene editing; release packages exclude it.
- terminal-cli for interactive Lua debugging in the development terminal; release packages exclude it.
- kristal-debug-tools for reusable battle startup debugging; release packages exclude it.
- .emacs and .helix for LuaLS, Kristal paths, and launch helpers.

## Builds

    just build
    just build-mod

The standalone builder stages stock Kristal and changes only target-Mod startup, window identity, and release/debug flags. Production packages keep localization, disable the object editor, exclude terminal-cli, and omit development files.

## Assets & Credits

| Asset                                                 | Source                                                      |
| ----------------------------------------------------- | ----------------------------------------------------------- |
| Battle music dog_buster (assets/music/dog_buster.ogg) | Original video: https://www.youtube.com/watch?v=NffMzWIkIn4 |

## License

Repository-authored Lua source and documentation are dual-licensed under Apache-2.0 (LICENSE-APACHE) or MIT (LICENSE-MIT). See third-party notices (THIRD_PARTY.md) for Kristal and submodule license boundaries.
