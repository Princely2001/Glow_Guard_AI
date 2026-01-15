import 'package:flutter/material.dart';
import '../services/Chemical_expert/expert_auth_service.dart';
import '../Chemical_expert/home_screen.dart' as expert;
import '../Chemical_expert/expert_login_screen.dart'; // change path if needed
import 'package:firebase_auth/firebase_auth.dart';


class ExpertRegisterScreen extends StatefulWidget {
  const ExpertRegisterScreen({super.key});

  @override
  State<ExpertRegisterScreen> createState() => _ExpertRegisterScreenState();
}

class _ExpertRegisterScreenState extends State<ExpertRegisterScreen> {
  final _service = ExpertAuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  DateTime? _dob;

  final _titles = const ["Dr.", "Mr.", "Ms.", "Mrs.", "Prof."];
  String _title = "Dr.";

  // ✅ Only BSc 1st Class + higher
  final _highestQualifications = const [
    "BSc (First Class / 1st Class Honours)",
    "MSc (Chemical-related)",
    "PhD (Chemical-related)",
  ];
  String _highestQualification = "BSc (First Class / 1st Class Honours)";

  final _experienceYears = List<int>.generate(31, (i) => i);
  int _exp = 0;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(now.year - 10, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _dobText() {
    if (_dob == null) return "Select date of birth";
    final d = _dob!;
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _register() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_dob == null) {
      _snack("Please select date of birth.");
      return;
    }

    if (_passC.text != _confirmC.text) {
      _snack("Passwords don't match.");
      return;
    }

    setState(() => _loading = true);

    try {
      final data = ExpertRegisterData(
        title: _title,
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        contactNumber: _phoneC.text.trim(),
        dateOfBirth: _dob!,
        experienceYears: _exp,
        educationLevel: _highestQualification,
        password: _passC.text,
      );

      await _service.registerExpert(data);

      // ✅ Decide based on experience rule
      final autoApproved = _exp > 5;

      if (!mounted) return;

      if (autoApproved) {
        _snack("Approved automatically ✅ (Experience > 5 years)");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const expert.HomeScreen()),
        );
      } else {
        _snack("Registered ✅ Pending approval (Experience must be > 5 years)");
        // optional: sign out so they don't stay logged in while pending
        await _service.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExpertLoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const teal = Color(0xFF009688);

    return Scaffold(
      appBar: AppBar(title: const Text("Expert Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title + name
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _title,
                      items: _titles
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: _loading ? null : (v) => setState(() => _title = v!),
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _nameC,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: "Name (e.g., Smith)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Name is required";
                        if (s.length < 2) return "Enter a valid name";
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Calling name: ${_title}${_nameC.text.trim().isEmpty ? "Smith" : _nameC.text.trim()}",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _emailC,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final s = (v ?? "").trim();
                  if (s.isEmpty) return "Email is required";
                  if (!s.contains("@") || !s.contains(".")) return "Enter a valid email";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneC,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Contact number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  final s = (v ?? "").trim();
                  if (s.isEmpty) return "Contact number is required";
                  if (s.length < 8) return "Enter a valid contact number";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: _loading ? null : _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date of birth",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(_dobText()),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _exp,
                items: _experienceYears
                    .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text("$y year${y == 1 ? "" : "s"}"),
                ))
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _exp = v ?? 0),
                decoration: const InputDecoration(
                  labelText: "Experience in chemical testing (years)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // fixed minimum degree
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Minimum Degree Required",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                child: const Text(
                  "BSc (First Class / 1st Class Honours)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _highestQualification,
                items: _highestQualifications
                    .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _highestQualification = v!),
                decoration: const InputDecoration(
                  labelText: "Highest qualification",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _passC,
                enabled: !_loading,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (v) {
                  final s = v ?? "";
                  if (s.isEmpty) return "Password is required";
                  if (s.length < 6) return "Minimum 6 characters";
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _confirmC,
                enabled: !_loading,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  final s = v ?? "";
                  if (s.isEmpty) return "Confirm your password";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    "Register as Chemical Expert",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Auto approval: Experience must be greater than 5 years.",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
