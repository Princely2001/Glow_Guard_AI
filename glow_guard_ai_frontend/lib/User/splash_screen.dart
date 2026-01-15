import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );

    _rotate = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );

    _c.repeat(reverse: true);

    // After splash time -> go to Login
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const teal = Color(0xFF009688);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE9FBF9),
              Color(0xFFF6FFFD),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.rotate(
                  angle: _rotate.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Logo (use Icon OR your image asset)
                        Container(
                          height: 92,
                          width: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                teal.withOpacity(0.95),
                                teal.withOpacity(0.70),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                                color: teal.withOpacity(0.22),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 44,
                            color: Colors.white,
                          ),

                          // If you have an asset logo, replace Icon with:
                          // child: Padding(
                          //   padding: const EdgeInsets.all(16),
                          //   child: Image.asset('assets/logo.png'),
                          // ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'GlowGuard AI',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
