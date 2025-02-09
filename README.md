# Marlin Firmware Builder

Inspired from https://github.com/ericdraken/MarlinBuilder and the excellent related blog article.

This tool allows you to fetch Marlin source code, Marlin configurations, Marlin docker builder, and build the firmware easily.
You will be able to tweak the configuration before building the firmware, but not the source code.

If you want to tweak Marlin source code before building the firmware, fork Marlin, tweak the source code and change the `MARLIN_SRC_REPO` variable in `build.sh`.

## Requirements

* git
* docker

## How to use

* Clone/fork this repo
* Run `./build.sh` to read about available options
* Run `./build.sh --cfg-subfolder <path-to-marlin-config-headers> --platform <platform>` to init config folder
* Edit `config/*.h` as you like
* Run `./build.sh --cfg-subfolder <path-to-marlin-config-headers> --platform <platform>` again to build the firmware

That's it!
