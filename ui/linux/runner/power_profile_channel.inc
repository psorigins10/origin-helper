// Merge into ui/linux/runner/my_application.cc.
// Includes:
#include "origin/power/power_profile.hpp"
#include <string>

// Handler functions (place before my_application_activate):
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

static void power_method_call_cb(FlMethodChannel* channel, FlMethodCall* call,
                                 gpointer user_data) {
  (void)channel;
  (void)user_data;
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "getProfile") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        profile_info_to_fl_value(power_profile.get())));
  } else if (g_strcmp0(method, "setProfile") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    FlValue* value = args ? fl_value_lookup_string(args, "profile") : nullptr;
    if (!value || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "invalid_arguments", "Expected string argument 'profile'.", nullptr));
    } else {
      std::string error;
      const std::string profile = fl_value_get_string(value);
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
  fl_method_call_respond(call, response, &error);
  if (error) g_warning("Power channel response failed: %s", error->message);
}

// Add this inside my_application_activate after fl_register_plugins(...):
// Keep the channel alive by attaching it to the FlView.
static void register_power_channel(FlView* view) {
  FlStandardMethodCodec* codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.origin.helper/power", FL_METHOD_CODEC(codec));
  g_object_unref(codec);
  fl_method_channel_set_method_call_handler(channel, power_method_call_cb, nullptr, nullptr);
  g_object_set_data_full(G_OBJECT(view), "origin-power-channel", channel, g_object_unref);
}
// Then call: register_power_channel(view);
