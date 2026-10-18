import 'package:flutter/material.dart';

void main() {
  runApp(const OriginHelperApp());
}

class OriginHelperApp extends StatelessWidget {
  const OriginHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9B8AFF);

    return MaterialApp(
      title: 'ORIGIN Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101014),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A22),
          elevation: 0,
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF28243D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFB7A8FF),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORIGIN',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                            ),
                          ),
                          Text(
                            'HELPER',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 3.0,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.settings_outlined, color: Colors.white60),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Your machine.',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Everything important, in one place.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF263A30),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.battery_charging_full_rounded,
                            color: Color(0xFF82E0A4),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Battery',
                                style: TextStyle(color: Colors.white60),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Hardware data pending',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.hourglass_empty_rounded,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PERFORMANCE MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _modeCard(
                      'Quiet',
                      'Less noise',
                      Icons.nights_stay_outlined,
                    ),
                    const SizedBox(width: 10),
                    _modeCard(
                      'Balanced',
                      'Everyday use',
                      Icons.balance_rounded,
                    ),
                    const SizedBox(width: 10),
                    _modeCard(
                      'Performance',
                      'More power',
                      Icons.rocket_launch_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.memory_rounded,
                          size: 27,
                          color: Color(0xFFB7A8FF),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'CPU, GPU, memory and temperatures',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'UI PREVIEW  •  HARDWARE CONTROLS NOT CONNECTED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String title, String subtitle, IconData icon) {
    final selected = selectedMode == title;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => selectedMode = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF29243F) : const Color(0xFF1A1A22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF9B8AFF)
                  : const Color(0xFF30303A),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFFB7A8FF) : Colors.white60,
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
