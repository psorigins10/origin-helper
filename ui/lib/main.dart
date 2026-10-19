import 'dart:io';

import 'package:flutter/material.dart' hide MenuItem;
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

const _powerChannel = MethodChannel('com.origin.helper/power');

Future<void> _positionBottomRight() async {
  await windowManager.setAlignment(Alignment.bottomRight);
  final pos = await windowManager.getPosition();
  await windowManager.setPosition(Offset(pos.dx - 16, pos.dy - 16));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(760, 760), minimumSize: Size(520, 560),
    title: 'ORIGIN Helper', backgroundColor: Color(0xFF101014),
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await _positionBottomRight();
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
  runApp(const OriginHelperApp());
}

class OriginHelperApp extends StatefulWidget {
  const OriginHelperApp({super.key});
  @override
  State<OriginHelperApp> createState() => _OriginHelperAppState();
}

class _OriginHelperAppState extends State<OriginHelperApp> with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initializeTray();
  }

  Future<void> _initializeTray() async {
    await trayManager.setIcon(Platform.isWindows ? 'assets/origin_tray.ico' : 'assets/origin_tray.png');
    if (!Platform.isLinux) await trayManager.setToolTip('ORIGIN Helper');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'open', label: 'Open ORIGIN Helper'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit ORIGIN Helper'),
    ]));
  }

  @override
  void onTrayIconMouseDown() => _showWindow();
  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();
  @override
  void onTrayMenuItemClick(MenuItem item) {
    if (item.key == 'open') _showWindow();
    if (item.key == 'quit') _quitApplication();
  }

  Future<void> _showWindow() async {
    await _positionBottomRight();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApplication() async {
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async => windowManager.hide();

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9B8AFF);
    return MaterialApp(
      title: 'ORIGIN Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101014),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A22), elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF30303A)),
          ),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedMode = 'Balanced';
  bool _loading = true;
  bool _setting = false;
  String? _error;
  String? _active;
  List<String> _available = [];

  static const Map<String, String> _modeProfiles = {
    'Quiet': 'low-power',
    'Balanced': 'balanced',
    'Performance': 'performance',
  };

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _powerChannel.invokeMapMethod<String, dynamic>('getProfile');
      if (!mounted) return;
      if (data == null) throw StateError('No response from native power backend.');
      final active = data['active'] as String? ?? '';
      final available = (data['available'] as List<dynamic>? ?? const []).whereType<String>().toList();
      setState(() {
        _active = active;
        _available = available;
        selectedMode = _modeProfiles.entries
            .where((entry) => entry.value == active)
            .map((entry) => entry.key)
            .firstOrNull ?? selectedMode;
        _error = (data['error'] as String?)?.isEmpty == true ? null : data['error'] as String?;
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message ?? e.code; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _setMode(String mode) async {
    final profile = _modeProfiles[mode]!;
    if (!_available.contains(profile)) {
      setState(() => _error = 'This device does not offer "$profile".');
      return;
    }
    setState(() { _setting = true; _error = null; });
    try {
      final data = await _powerChannel.invokeMapMethod<String, dynamic>(
        'setProfile', <String, Object>{'profile': profile},
      );
      if (!mounted) return;
      if (data == null) throw StateError('No response from native power backend.');
      final active = data['active'] as String? ?? '';
      final error = data['error'] as String? ?? '';
      setState(() {
        _active = active;
        if (error.isEmpty && active == profile) {
          selectedMode = mode;
          _error = null;
        } else {
          _error = error.isEmpty ? 'System did not confirm the requested profile.' : error;
        }
        _setting = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message ?? e.code; _setting = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _setting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFF28243D), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFB7A8FF), size: 27),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ORIGIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
                    Text('HELPER', style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white54)),
                  ])),
                  const Icon(Icons.settings_outlined, color: Colors.white60),
                ]),
                const SizedBox(height: 30),
                const Text('Your machine.', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text('Everything important, in one place.', style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 22),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(color: const Color(0xFF263A30), borderRadius: BorderRadius.circular(17)),
                      child: const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF82E0A4), size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Battery', style: TextStyle(color: Colors.white60)),
                      SizedBox(height: 5),
                      Text('Hardware data pending', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ])),
                    const Icon(Icons.hourglass_empty_rounded, color: Colors.white38),
                  ]),
                )),
                const SizedBox(height: 24),
                const Text('PERFORMANCE MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: Colors.white54)),
                const SizedBox(height: 12),
                Row(children: [
                  _modeCard('Quiet', 'Less noise', Icons.nights_stay_outlined),
                  const SizedBox(width: 10),
                  _modeCard('Balanced', 'Everyday use', Icons.balance_rounded),
                  const SizedBox(width: 10),
                  _modeCard('Performance', 'More power', Icons.rocket_launch_outlined),
                ]),
                if (_loading || _setting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (_active != null || _error != null) ...[
                  const SizedBox(height: 12),
                  Card(child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(_error == null ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                        color: _error == null ? const Color(0xFF82E0A4) : const Color(0xFFFFD18A)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_error == null ? 'System power profile' : 'Power profile status',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_error ?? 'Active: ${_active ?? "unknown"}\\nAvailable: ${_available.join(", ")}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        if (_error != null)
                          TextButton(onPressed: _loading || _setting ? null : _refreshProfile, child: const Text('Retry')),
                      ])),
                    ]),
                  )),
                ],
                const SizedBox(height: 24),
                Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const Icon(Icons.memory_rounded, size: 27, color: Color(0xFFB7A8FF)),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('System information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('CPU, GPU, memory and temperatures', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ]),
                )),
                const SizedBox(height: 18),
                Center(child: Text(
                  _active == null ? 'ORIGIN HELPER  •  POWER PROFILE STATUS UNKNOWN' : 'ORIGIN HELPER  •  POWER PROFILE CONNECTED',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.1),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String title, String subtitle, IconData icon) {
    final profile = _modeProfiles[title]!;
    final available = _available.contains(profile);
    final selected = selectedMode == title;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _loading || _setting || !available ? null : () => _setMode(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF29243F) : const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFF9B8AFF) : const Color(0xFF30303A)),
        ),
        child: Opacity(opacity: available || _loading ? 1 : 0.45, child: Column(children: [
          Icon(icon, color: selected ? const Color(0xFFB7A8FF) : Colors.white60, size: 24),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ])),
      ),
    ));
  }
}
