# ORIGIN Helper power profile integration

Copy the files in this archive into the matching paths in your repository. It preserves the dashboard's existing theme and tray/window behavior while adding real power-profile loading and selection.

## Important: native bridge
`ui/linux/runner/power_profile_channel.inc` contains the handler code to merge into `my_application.cc`:
1. Add the listed includes.
2. Add the handler functions before `my_application_activate`.
3. Add `register_power_channel(view);` immediately after `fl_register_plugins(FL_PLUGIN_REGISTRY(view));` inside `my_application_activate`.

The channel must be registered or Dart calls will return MissingPluginException. Channel name: `com.origin.helper/power`.

## Build
```bash
cd ~/programming/origin-helper
cmake -S . -B build
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure
cd ui
flutter pub get
flutter build linux
```
Do not run the app as root or loosen sysfs permissions. Permission denial is reported in the UI.
