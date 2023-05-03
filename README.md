# Marlin Firmware Builder

Inspired from https://github.com/ericdraken/MarlinBuilder and the excellent related blog article.

This tool allows you to fetch Marlin source code, Marlin configurations, Marlin docker builder, and build the firmware easily.
You will be able to tweak the configuration before building the firmware, but not the source code.

If you want to tweak Marlin source code before building the firmware, fork Marlin, tweak the source code and change the `MARLIN_SRC_REPO` variable in `build.sh`.

## Requirements

* git
* docker
* docker compose

## How to use

* Clone/fork this repo
* Edit `build.sh` to set variables
* Run `./build.sh` to init config folder
* Edit `config/*.h` as you like
* Run `./build.sh` again to build the firmware

That's it!
