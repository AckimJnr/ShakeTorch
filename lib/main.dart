import 'package:flutter/material.dart';
import 'package:shake_torch/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';
import 'package:shake_torch/about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("FLUTTER_BACKGROUND_SERVICE: main() started");
  // Initialize the background service
  await initializeService();
  print("FLUTTER_BACKGROUND_SERVICE: initializeService() returned");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShakeTorch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ShakeTorchHome(),
    );
  }
}

class ShakeTorchHome extends StatefulWidget {
  const ShakeTorchHome({super.key});

  @override
  State<ShakeTorchHome> createState() => _ShakeTorchHomeState();
}

class _ShakeTorchHomeState extends State<ShakeTorchHome>
    with WidgetsBindingObserver {
  bool isTorchOn = false;
  double sensitivity = 5.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _checkInitialState();
    _loadSensitivity();

    // Listen for updates from the background service
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null && event['isTorchOn'] != null) {
        if (mounted) {
          setState(() {
            isTorchOn = event['isTorchOn'];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Attempt to re-sync state on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialState();
    }
  }

  // Simple state check/permissions
  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.notification.request();
  }

  Future<void> _checkInitialState() async {
    // We can't easily query the torch state from hardware in all plugins,
    // but we can ask the service or just rely on the stream.
  }

  Future<void> _loadSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sensitivity = prefs.getDouble('shake_sensitivity') ?? 5.0;
    });
  }

  Future<void> _updateSensitivity(double value) async {
    setState(() {
      sensitivity = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shake_sensitivity', value);

    // Notify background service
    FlutterBackgroundService().invoke("setSensitivity", {"sensitivity": value});
  }

  Future<void> _toggleTorch() async {
    try {
      bool newState = !isTorchOn;
      if (newState) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }

      setState(() {
        isTorchOn = newState;
      });

      // Notify background service of the manual change so it stays in sync
      FlutterBackgroundService().invoke("setTorch", {"state": newState});
    } catch (e) {
      debugPrint("Error toggling torch: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not toggle torch: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('ShakeTorch'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTorchOn
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.transparent,
                    boxShadow: isTorchOn
                        ? [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.5),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.3),
                              blurRadius: 100,
                              spreadRadius: 40,
                            ),
                          ]
                        : [],
                  ),
                ),

                // The main button/indicator
                GestureDetector(
                  onTap: _toggleTorch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isTorchOn
                          ? const RadialGradient(
                              colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF424242), Color(0xFF212121)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(5, 5),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          offset: const Offset(-5, -5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flashlight_on_rounded,
                      size: 80,
                      color: isTorchOn ? Colors.black87 : Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isTorchOn ? Colors.amber : Colors.white24,
                letterSpacing: 2.0,
              ),
              child: Text(isTorchOn ? "TORCH ON" : "TORCH OFF"),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vibration, color: Colors.white54, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Shake active in background",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sensitivity",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        sensitivity.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 12.0,
                      activeTrackColor: Colors.amber,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.amber,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 16.0,
                      ),
                      overlayColor: Colors.amber.withOpacity(0.2),
                      valueIndicatorColor: Colors.amber,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    child: Slider(
                      value: sensitivity,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      label: sensitivity.toStringAsFixed(1),
                      onChanged: _updateSensitivity,
                    ),
                  ),
                  const Text(
                    "Lower is more sensitive",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
