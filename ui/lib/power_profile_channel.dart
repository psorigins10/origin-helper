import 'package:flutter/services.dart';

class PowerProfileChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.origin.helper/power',
  );

  static Future<Map<String, dynamic>> getProfile() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getProfile',
    );
    if (result == null) {
      throw PlatformException(
        code: 'empty_result',
        message: 'No power profile data returned.',
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> setProfile(String profile) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'setProfile',
      <String, Object>{'profile': profile},
    );
    if (result == null) {
      throw PlatformException(
        code: 'empty_result',
        message: 'No result returned.',
      );
    }
    return result;
  }
}
