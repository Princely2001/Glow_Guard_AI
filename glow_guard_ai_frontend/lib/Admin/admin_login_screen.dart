import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Added Firebase Auth import

import 'admin_verification_screen.dart';
import '../User/login_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _pressed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _c.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // UPDATED: Now actually logs into Firebase Authentication
  Future<void> _loginAdmin() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    try {
      final String email = _emailC.text.trim();
      final String password = _passC.text;

      // Secure login via Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Success! Navigate to the Admin Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
      );

    } on FirebaseAuthException catch (e) {
      // Firebase will tell us if the password is wrong or user doesn't exist
      _snack(e.message ?? "Incorrect Admin Email or Password.");
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Using a slightly different color scheme (Blue/Grey) for Admin to distinguish it visually
    const adminColor = Color(0xFF455A64);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Positioned(top: -120, left: -80, child: _Blob(color: adminColor.withOpacity(0.16), size: 260)),
          Positioned(bottom: -140, right: -90, child: _Blob(color: adminColor.withOpacity(0.14), size: 320)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeInOut,
                                builder: (context, t, _) {
                                  final dy = math.sin(t * math.pi * 2) * 4.5;
                                  return Transform.translate(
                                    offset: Offset(0, dy),
                                    child: const _LogoBadge(icon: Icons.admin_panel_settings, color: adminColor),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'Admin Portal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                'Login to manage experts\nand system verification workflows.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 22),

                              _NiceField(
                                controller: _emailC,
                                label: 'Admin Email',
                                hint: 'admin@glowguard.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return "Email is required";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _NiceField(
                                controller: _passC,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                obscureText: _obscure,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                                validator: (v) {
                                  final s = (v ?? '');
                                  if (s.isEmpty) return "Password is required";
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              GestureDetector(
                                onTapDown: (_) => setState(() => _pressed = true),
                                onTapUp: (_) => setState(() => _pressed = false),
                                onTapCancel: () => setState(() => _pressed = false),
                                child: AnimatedScale(
                                  scale: _pressed ? 0.98 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOut,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _loginAdmin,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      backgroundColor: adminColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : const Text(
                                      'Secure Login',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              TextButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back to User Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- UI pieces ----------

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _LogoBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 78,
        width: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.95), color.withOpacity(0.70)],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: color.withOpacity(0.22),
            ),
          ],
        ),
        child: Icon(icon, size: 38, color: Colors.white),
      ),
    );
  }
}

class _NiceField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const _NiceField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}