# ORIGIN Helper power-profile bridge patch

This patch adds the backend source to the root CMake build and provides a Linux
Flutter MethodChannel bridge implementation for the existing `PowerProfile`
C++ class.

## Files to copy

- Replace root `CMakeLists.txt` with the bundled version.
- Replace `ui/linux/runner/CMakeLists.txt` with the bundled version.
- Copy `ui/lib/power_profile_channel.dart` into your app.
- Merge the native handler below into `ui/linux/runner/my_application.cc`.

The channel name is `com.origin.helper/power`. Supported methods:
- `getProfile` -> `{active, available, supported, error}`
- `setProfile` with `{profile: "balanced"}` -> same map; `error` is non-empty on failure.

The Dart helper intentionally does not modify `main.dart` because its full current
contents were not included in the pasted terminal output. After the native bridge
builds, wire the existing Quiet/Balanced/Performance selector to this helper.
Map Quiet -> `low-power`, Balanced -> `balanced`, Performance -> `performance`.
Do not map Performance to `max-power` automatically; only offer max-power if the
UI explicitly supports a separate maximum-power mode.

## Native handler code

Add these includes near the top of `my_application.cc`:

```cpp
#include "origin/power/power_profile.hpp"
#include <flutter_linux/fl_method_channel.h>
#include <flutter_linux/fl_standard_method_codec.h>
#include <string>
```

Add this handler before `my_application_activate`:

```cpp
static origin::PowerProfile power_profile;

static FlValue* profile_info_to_fl_value(const origin::PowerProfileInfo& info) {
  FlValue* result = fl_value_new_map();
  fl_value_set_string(result, "active", fl_value_new_string(info.active.c_str()));
  fl_value_set_string(result, "supported", fl_value_new_bool(info.supported));
  fl_value_set_string(result, "error", fl_value_new_string(info.error.c_str()));

  FlValue* available = fl_value_new_list();
  for (const auto& item : info.available) {
    fl_value_append(available, fl_value_new_string(item.c_str()));
  }
  fl_value_set_string(result, "available", available);
  return result;
}

static void power_method_call_cb(FlMethodChannel* channel,
                                 FlMethodCall* method_call,
                                 gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "getProfile") == 0) {
    const auto info = power_profile.get();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        profile_info_to_fl_value(info)));
  } else if (g_strcmp0(method, "setProfile") == 0) {
    const FlValue* args = fl_method_call_get_args(method_call);
    const FlValue* profile_value =
        args != nullptr ? fl_value_lookup_string(args, "profile") : nullptr;

    if (profile_value == nullptr ||
        fl_value_get_type(profile_value) != FL_VALUE_TYPE_STRING) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "invalid_arguments", "Expected a string argument named 'profile'.",
          nullptr));
    } else {
      std::string error;
      const std::string profile = fl_value_get_string(profile_value);
      if (power_profile.set(profile, error)) {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(
            profile_info_to_fl_value(power_profile.get())));
      } else {
        auto info = power_profile.get();
        info.error = error;
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(
            profile_info_to_fl_value(info)));
      }
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  fl_method_call_respond(method_call, response, &error);
  if (error != nullptr) {
    g_warning("Failed to respond to power method call: %s", error->message);
  }
}
```

Inside `my_application_activate`, after `fl_register_plugins(FL_PLUGIN_REGISTRY(view));`,
register the channel:

```cpp
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) power_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.origin.helper/power",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      power_channel, power_method_call_cb, nullptr, nullptr);
```

## Build and test

```bash
cd ~/programming/origin-helper
cmake -S . -B build
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure

cd ui
flutter pub get
flutter build linux
```

If the Linux Flutter API differs in your installed Flutter version, share the
compiler error verbatim and adjust the handler to that SDK. Do not run the app as
root and do not make the sysfs file world-writable. A permission-denied result is
expected if your user cannot write the platform-profile file.
