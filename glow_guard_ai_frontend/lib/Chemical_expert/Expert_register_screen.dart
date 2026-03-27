import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/Chemical_expert/expert_auth_service.dart';
import '../Chemical_expert/expert_login_screen.dart'; // Ensure this matches your file path case
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
  final _regIdC = TextEditingController(); // ✅ Added Controller for Gov. Registration ID
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  DateTime? _dob;
  File? _credentialFile;

  final _titles = const ["Dr.", "Mr.", "Ms.", "Mrs.", "Prof."];
  String _title = "Dr.";

  // ✅ Added Sri Lankan Districts
  final _sriLankanDistricts = const [
    "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo",
    "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara",
    "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar",
    "Matale", "Matara", "Moneragala", "Mullaitivu", "Nuwara Eliya",
    "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
  ];
  String? _selectedDistrict; // ✅ State variable for location

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
    _regIdC.dispose(); // ✅ Dispose new controller
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

  Future<void> _pickCredentialFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _credentialFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _register() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_dob == null) {
      _snack("Please select date of birth.");
      return;
    }

    if (_selectedDistrict == null) {
      _snack("Please select your district.");
      return;
    }

    if (_credentialFile == null) {
      _snack("Please upload your degree or lab certification.");
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
        govRegistrationId: _regIdC.text.trim(), // ✅ Pass the Gov ID
        dateOfBirth: _dob!,
        experienceYears: _exp,
        educationLevel: _highestQualification,
        location: _selectedDistrict!, // ✅ Pass the selected district
        password: _passC.text,
        credentialFile: _credentialFile,
      );

      await _service.registerExpert(data);

      if (!mounted) return;

      // SUCCESS MESSAGE: Informs user to check email
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Application Submitted"),
          content: const Text("Your registration is now pending admin review. A confirmation email has been sent to you. Please check your inbox (and spam folder) for updates."),
          actions: [
            TextButton(
              onPressed: () async {
                await _service.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpertLoginScreen()),
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );

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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _title,
                      items: _titles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: _loading ? null : (v) => setState(() => _title = v!),
                      decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _nameC,
                      enabled: !_loading,
                      decoration: const InputDecoration(labelText: "Name (e.g., Smith)", border: OutlineInputBorder()),
                      validator: (v) => (v ?? "").trim().isEmpty ? "Name is required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailC,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if ((v ?? "").trim().isEmpty) return "Email is required";
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v!)) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneC,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Contact number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => (v ?? "").trim().isEmpty ? "Contact number is required" : null,
              ),
              const SizedBox(height: 12),

              // ✅ Added Gov. Registration ID Field
              TextFormField(
                controller: _regIdC,
                enabled: !_loading,
                decoration: const InputDecoration(
                    labelText: "Gov. Registration ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined)
                ),
                validator: (v) => (v ?? "").trim().isEmpty ? "Registration ID is required" : null,
              ),
              const SizedBox(height: 12),

              // ✅ Added District Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                hint: const Text("Select District"),
                items: _sriLankanDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _selectedDistrict = v),
                decoration: const InputDecoration(
                    labelText: "District",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city_outlined)
                ),
                validator: (v) => v == null || v.isEmpty ? "Please select a district" : null,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _loading ? null : _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Date of birth", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake_outlined)),
                  child: Text(_dobText()),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _exp,
                items: _experienceYears.map((y) => DropdownMenuItem(value: y, child: Text("$y year${y == 1 ? "" : "s"}"))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _exp = v ?? 0),
                decoration: const InputDecoration(labelText: "Experience (years)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.science_outlined)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _highestQualification,
                items: _highestQualifications.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                onChanged: _loading ? null : (v) => setState(() => _highestQualification = v!),
                decoration: const InputDecoration(labelText: "Highest qualification", border: OutlineInputBorder(), prefixIcon: Icon(Icons.verified_outlined)),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text("Upload Credentials", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text("Please upload a clear copy of your degree or lab certification (PDF/Image).", textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _pickCredentialFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_credentialFile == null ? "Select Document" : "Change Document"),
                    ),
                    if (_credentialFile != null) ...[
                      const SizedBox(height: 8),
                      Text("Selected: ${_credentialFile!.path.split('/').last}", style: const TextStyle(color: teal, fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passC,
                enabled: !_loading,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password", border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                ),
                validator: (v) => (v ?? "").length < 6 ? "Minimum 6 characters" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmC,
                enabled: !_loading,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v ?? "").isEmpty ? "Confirm your password" : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Submit Application", style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}