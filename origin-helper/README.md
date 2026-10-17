# ORIGIN Helper

A C++20 laptop hardware management utility for Linux, designed with a
modular architecture and a long-term goal of integration with ORIGIN OS.

## Current status

Early development: version 0.1.0.

Currently implemented:
- Linux distribution identification via `/etc/os-release`
- CPU identification via `/proc/cpuinfo`
- Battery discovery and charge percentage via sysfs
- Version reporting
- Initial automated test target

Hardware controls are not implemented yet. Battery charging limits,
performance profiles, fan control, and GPU controls will only be added
after verifying hardware and driver support.

## Requirements

- Linux
- C++20 compiler
- CMake 3.20+
- Make or Ninja

On Arch Linux:

    sudo pacman -S --needed base-devel cmake

## Build

    cmake -S . -B build
    cmake --build build

## Run

    ./build/origin-helper
    ./build/origin-helper --version

## Test

    ctest --test-dir build --output-on-failure

## Safety

The initial version only reads system information. It does not modify
hardware settings or write to privileged system interfaces.

## License

This project is intended to use the Apache License 2.0. See LICENSE.
