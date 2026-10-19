# ORIGIN Flutter power profile bridge — integration files

This archive contains:
- Updated root CMakeLists.txt (adds src/power/power_profile.cpp to origin-core)
- `include/origin/power/power_profile.hpp`
- `src/power/power_profile.cpp`
- Dart MethodChannel helper snippet

## Critical: GTK runner integration remains a targeted edit
Your `ui/linux/runner/my_application.cc` was not included in the user-provided output,
so this archive does not overwrite it with a guessed version. Register the channel
there using Flutter's generated `FlMethodChannel` API and the channel name
`com.origin.helper/power`, with methods `getPowerProfile` and `setPowerProfile`.
The handler should call `origin::PowerProfile::get()` / `.set()` and return a
Map containing `active`, `available`, `supported`, and optionally `error`.

Add the repo's `include/` and `src/` files to their matching paths, and replace the
root CMakeLists.txt. The Linux runner's `ui/linux/runner/CMakeLists.txt` must link
`origin-core` and include the repository's `include` directory; use paths relative
to `${CMAKE_CURRENT_SOURCE_DIR}`:
```cmake
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../../../include")
target_link_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")
target_link_libraries(${BINARY_NAME} PRIVATE origin-core)
```
This linking pattern assumes `origin-core` has already been built in the root `build`
directory and is not robust for Flutter's independent build directory. Prefer adding
the repo root as a subdirectory from the runner CMake or using an explicit imported
library target; adjust to the actual runner CMake before applying.

## Permissions
Never run Flutter as root and never make sysfs world-writable. A write failure should
be surfaced in the UI. If write access is denied, add a narrowly scoped privileged
helper later.
