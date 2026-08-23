import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const DemonCoreApp());
}

class DemonCoreApp extends StatelessWidget {
  const DemonCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0033),
          surface: Colors.black,
        ),
      ),
      home: const DemonCoreMainScreen(),
    );
  }
}

class DemonCoreMainScreen extends StatefulWidget {
  const DemonCoreMainScreen({super.key});

  @override
  State<DemonCoreMainScreen> createState() => _DemonCoreMainScreenState();
}

class _DemonCoreMainScreenState extends State<DemonCoreMainScreen> {
  bool _isAwakened = false;
  bool _isAwakening = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batterySubscription;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  void _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
      _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
        if (mounted) setState(() => _batteryState = state);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }

  void _startAwakening() {
    setState(() {
      _isAwakening = true;
      _holdProgress = 0.0;
    });

    Vibration.vibrate(duration: 1000, amplitude: 64);

    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _holdProgress += 0.025;
      });

      if (_holdProgress >= 0.5 && _holdProgress < 0.52) {
        Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 128, 0, 255]);
      }

      if (_holdProgress >= 1.0) {
        timer.cancel();
        _completeAwakening();
      }
    });
  }

  void _cancelAwakening() {
    if (_isAwakened) return;
    _holdTimer?.cancel();
    Vibration.cancel();
    setState(() {
      _isAwakening = false;
      _holdProgress = 0.0;
    });
  }

  void _completeAwakening() {
    Vibration.vibrate(duration: 500, amplitude: 255);
    setState(() {
      _isAwakening = false;
      _isAwakened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              radialGradient: RadialGradient(
                colors: [
                  const Color(0xFFFF0033).withOpacity(_isAwakened ? 0.25 : 0.08),
                  Colors.black,
                ],
                radius: 1.2,
              ),
            ),
          ),
          SafeArea(
            child: _isAwakened ? _buildHUD() : _buildDormantScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildDormantScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: _fieldStatusRow(),
        ),
        GestureDetector(
          onTapDown: (_) => _startAwakening(),
          onTapUp: (_) => _cancelAwakening(),
          onTapCancel: () => _cancelAwakening(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isAwakening)
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _holdProgress,
                    color: const Color(0xFFFF0033),
                    strokeWidth: 4,
                  ),
                ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF0033),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0033).withOpacity(0.8),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.1, duration: 1200.ms, curve: Curves.easeInOut),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Text(
            _isAwakening ? "AWAKENING..." : "HOLD TO AWAKEN",
            style: TextStyle(
              color: const Color(0xFFFF0033).withOpacity(0.8),
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldStatusRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusItem("❤️ Core Power", "$_batteryLevel%"),
        _statusItem("🩸 Blood Energy", "87%"),
        _statusItem("👑 Sovereign Status", "Dormant"),
        _statusItem("🌑 Demon Aura", "OFF"),
      ],
    );
  }

  Widget _statusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFFFF0033), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "DEMON SOVEREIGN",
          style: TextStyle(color: Color(0xFFFF0033), fontSize: 24, fontWeight: FontWeight.black, letterSpacing: 6),
        ),
        Text(
          _batteryState == BatteryState.charging ? "CORE RECHARGING..." : "SYSTEM STABLE",
          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2),
        ),
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF0033),
            boxShadow: [BoxShadow(color: Color(0xFFFF0033), blurRadius: 40)],
          ),
          child: const Icon(Icons.shield, color: Colors.black, size: 40),
        ),
        const Spacer(),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _hudButton("BLOOD ART 🩸", () => _triggerArt("Blood Art Executed")),
            _hudButton("SHADOW STEP 🌑", () => _triggerArt("Shadow Step Active")),
            _hudButton("REGENERATION ♻️", () => _triggerArt("Regenerating Core")),
            _hudButton("DOMAIN 🔴", () => _triggerArt("Domain Expanded")),
            _hudButton("ARSENAL ⚔️", () => _triggerArt("Arsenal Summoned")),
            _hudButton("SOVEREIGN 👑", () => _triggerArt("Sovereign Power")),
          ],
        ),
      ],
    );
  }

  Widget _hudButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFFF0033), width: 1.5),
        backgroundColor: Colors.black54,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _triggerArt(String message) {
    Vibration.vibrate(duration: 100);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF0033),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }
}
