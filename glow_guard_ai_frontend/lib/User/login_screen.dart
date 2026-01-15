import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/User/user_auth_service.dart';
import '../User/user_shell.dart';
import 'register_screen.dart';
import '../Chemical_expert/Expert_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _service = UserLoginService();

  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _pressedUser = false;
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

  Future<void> _login() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    try {
      await _service.loginUser(
        email: _emailC.text,
        password: _passC.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserShell()),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _snack("No account found for that email.");
          break;
        case 'wrong-password':
          _snack("Incorrect password.");
          break;
        case 'invalid-email':
          _snack("Please enter a valid email address.");
          break;
        case 'too-many-requests':
          _snack("Too many attempts. Try again later.");
          break;
        case 'network-request-failed':
          _snack("Network error. Check your internet connection.");
          break;
        case 'no-user-profile':
          _snack("No user profile found. Please register again.");
          break;
        default:
          _snack("Login failed: ${e.message ?? e.code}");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailC.text.trim();
    if (email.isEmpty) {
      _snack("Enter your email first, then tap 'Forgot password?'.");
      return;
    }

    try {
      await _service.sendPasswordReset(email);
      _snack("Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      _snack("Reset failed: ${e.message ?? e.code}");
    } catch (e) {
      _snack("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const teal = Color(0xFF009688);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9FBF9), Color(0xFFF6FFFD), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Positioned(top: -120, left: -80, child: _Blob(color: teal.withOpacity(0.16), size: 260)),
          Positioned(bottom: -140, right: -90, child: _Blob(color: cs.secondary.withOpacity(0.14), size: 320)),

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
                                    child: const _LogoBadge(),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              const Text(
                                'GlowGuard AI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                'Detect illicit ingredients in cosmetics\nwith smart safety guidance.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 22),

                              _NiceField(
                                controller: _emailC,
                                label: 'Email',
                                hint: 'you@example.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return "Email is required";
                                  if (!s.contains('@') || !s.contains('.')) return "Enter a valid email";
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
                                  if (s.length < 6) return "Password must be at least 6 characters";
                                  return null;
                                },
                              ),

                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ),

                              const SizedBox(height: 8),

                              GestureDetector(
                                onTapDown: (_) => setState(() => _pressedUser = true),
                                onTapUp: (_) => setState(() => _pressedUser = false),
                                onTapCancel: () => setState(() => _pressedUser = false),
                                child: AnimatedScale(
                                  scale: _pressedUser ? 0.98 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOut,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      backgroundColor: teal,
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
                                      'Login',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ExpertLoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Login as Chemical Expert'),
                              ),

                              const SizedBox(height: 12),

                              OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_outlined),
                                label: const Text('Create an Account'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
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
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
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
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF009688);
    return Center(
      child: Container(
        height: 78,
        width: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [teal.withOpacity(0.95), teal.withOpacity(0.70)],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: teal.withOpacity(0.22),
            ),
          ],
        ),
        child: const Icon(Icons.shield_outlined, size: 38, color: Colors.white),
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
        fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
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
