import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user/user_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _service = UserAuthService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late final String _userId;

  String _gender = "Male";
  DateTime? _dob;

  String _cosmeticExp = "Beginner";
  String _chemicalExp = "Beginner";
  String _education = "High school";

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _busy = false;

  final List<String> educationLevels = const [
    "No formal education",
    "Primary school",
    "Secondary school",
    "High school",
    "Diploma",
    "Higher Diploma",
    "Bachelor’s degree",
    "Postgraduate Diploma",
    "Master’s degree",
    "MPhil",
    "PhD",
    "Pharmacy",
    "Chemistry",
    "Chemical Engineering",
    "Cosmetic Science",
    "Dermatology",
    "Laboratory Technician",
    "Other",
  ];

  final List<String> experienceLevels = const [
    "Beginner",
    "Intermediate",
    "Advanced",
    "Professional",
  ];

  @override
  void initState() {
    super.initState();

    // ✅ system-generated ID
    _userId = UserAuthService.generateUserId();

    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _register() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_dob == null) {
      _snack("Please select Date of Birth");
      return;
    }

    if (_password.text.trim() != _confirm.text.trim()) {
      _snack("Passwords don't match");
      return;
    }

    setState(() => _busy = true);

    try {
      final data = UserRegisterData(
        userId: _userId,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        gender: _gender,
        dob: _dob!,
        education: _education,
        cosmeticExp: _cosmeticExp,
        chemicalExp: _chemicalExp,
        password: _password.text.trim(),
      );

      await _service.registerUser(data);

      if (!mounted) return;
      _snack("Account created! Your ID: $_userId");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Registration failed";
      if (e.code == "email-already-in-use") msg = "This email is already registered.";
      if (e.code == "invalid-email") msg = "Please enter a valid email address.";
      if (e.code == "weak-password") msg = "Password is too weak (min 6 chars).";
      _snack(msg);
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const _Logo(),
                  const SizedBox(height: 8),

                  // User ID read-only
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "User ID: $_userId",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _field(
                    label: "Full Name",
                    controller: _name,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Enter your name" : null,
                  ),

                  _field(
                    label: "Email",
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return "Enter email";
                      if (!s.contains('@') || !s.contains('.')) return "Enter valid email";
                      return null;
                    },
                  ),

                  _field(
                    label: "Phone Number",
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return "Enter contact number";
                      if (s.length < 7) return "Enter valid number";
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: const ["Male", "Female", "Other"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v ?? "Male"),
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickDob,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _dob == null
                            ? "Select Date of Birth"
                            : DateFormat("yyyy-MM-dd").format(_dob!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _education,
                    items: educationLevels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _education = v ?? "High school"),
                    decoration: const InputDecoration(
                      labelText: "Education Level",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _cosmeticExp,
                    items: experienceLevels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _cosmeticExp = v ?? "Beginner"),
                    decoration: const InputDecoration(
                      labelText: "Cosmetics Experience",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _chemicalExp,
                    items: experienceLevels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _chemicalExp = v ?? "Beginner"),
                    decoration: const InputDecoration(
                      labelText: "Chemical Testing Experience",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _field(
                    label: "Password",
                    controller: _password,
                    obscureText: _obscure1,
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.isEmpty) return "Enter password";
                      if (s.length < 6) return "Password must be at least 6 characters";
                      return null;
                    },
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(_obscure1
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),

                  _field(
                    label: "Confirm Password",
                    controller: _confirm,
                    obscureText: _obscure2,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return "Confirm password";
                      return null;
                    },
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(_obscure2
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),

                  const SizedBox(height: 18),

                  FilledButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Create Account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const Icon(Icons.person_add, color: Colors.white, size: 36),
    );
  }
}
