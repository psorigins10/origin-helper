// Add near the imports in ui/lib/main.dart:
import 'package:flutter/services.dart';

// Add to _DashboardPageState:
static const MethodChannel _powerChannel =
    MethodChannel('com.origin.helper/power');

String? powerError;
bool powerLoading = false;
String activeProfile = 'unknown';
List<String> availableProfiles = const [];

Future<void> loadPowerProfile() async {
  try {
    final result = await _powerChannel.invokeMapMethod<String, dynamic>(
      'getPowerProfile',
    );
    if (!mounted || result == null) return;
    setState(() {
      activeProfile = result['active'] as String? ?? 'unknown';
      availableProfiles =
          (result['available'] as List<dynamic>? ?? []).cast<String>();
      powerError = result['error'] as String?;
    });
  } on PlatformException catch (e) {
    if (!mounted) return;
    setState(() => powerError = e.message ?? 'Could not read power profile.');
  }
}

Future<void> setPowerProfile(String profile) async {
  if (powerLoading) return;
  setState(() {
    powerLoading = true;
    powerError = null;
  });
  try {
    final result = await _powerChannel.invokeMapMethod<String, dynamic>(
      'setPowerProfile',
      {'profile': profile},
    );
    if (!mounted || result == null) return;
    setState(() {
      activeProfile = result['active'] as String? ?? activeProfile;
      powerError = result['error'] as String?;
    });
  } on PlatformException catch (e) {
    if (mounted) setState(() => powerError = e.message ?? 'Could not set profile.');
  } finally {
    if (mounted) setState(() => powerLoading = false);
  }
}

// Call loadPowerProfile() from initState().
// Map the current cards to these profile names:
// Quiet -> low-power, Balanced -> balanced, Performance -> performance.
// Only enable a card if availableProfiles contains its mapped profile.
// Call setPowerProfile(mappedProfile) when a card is tapped.
// Display powerError in the existing UI when non-null.
