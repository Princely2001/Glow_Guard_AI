import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/common_widgets.dart';
import '../services/User/report_service.dart';
// ✅ Import the new public database screen
import 'public_hazard_reports_screen.dart';

// Class to hold data for each specific timeline stage
class TimelineStepData {
  String sideEffects = "";
  double severity = 1.0;
  File? image;

  bool get hasData => sideEffects.isNotEmpty || severity > 1.0 || image != null;
}

class DangerousProductReportScreen extends StatefulWidget {
  const DangerousProductReportScreen({super.key});

  @override
  State<DangerousProductReportScreen> createState() => _DangerousProductReportScreenState();
}

class _DangerousProductReportScreenState extends State<DangerousProductReportScreen> {
  // State Variables
  bool _isAnonymous = true;
  int _currentTimelineStep = 0;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _sideEffectsController = TextEditingController();

  // Services
  final ImagePicker _picker = ImagePicker();
  final ReportService _reportService = ReportService();

  final List<String> _timelineLabels = [
    "First 3 Days", "First Week", "Second Week", "Third Week", "One Month", "Three Months"
  ];

  // Map to hold individual data for each timeline step
  final Map<int, TimelineStepData> _timelineData = {};

  @override
  void initState() {
    super.initState();
    // Initialize data storage for each step
    for (int i = 0; i < _timelineLabels.length; i++) {
      _timelineData[i] = TimelineStepData();
    }
  }

  @override
  void dispose() {
    // Save final text state before disposing if needed
    _productNameController.dispose();
    _brandController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  // --- UI Logic: Switching Steps ---
  void _changeTimelineStep(int index) {
    // Save current step's text data before switching
    _timelineData[_currentTimelineStep]!.sideEffects = _sideEffectsController.text;

    setState(() {
      _currentTimelineStep = index;
      // Load the new step's text data
      _sideEffectsController.text = _timelineData[index]!.sideEffects;
    });
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _timelineData[_currentTimelineStep]!.image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  // --- Submission Logic ---
  Future<void> _submitReport() async {
    if (_productNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the product name", style: TextStyle(color: Colors.white))),
      );
      return;
    }

    // Save the text of the currently active step
    _timelineData[_currentTimelineStep]!.sideEffects = _sideEffectsController.text.trim();

    // Compile timeline data that actually has user input
    List<Map<String, dynamic>> compiledTimeline = [];
    for (int i = 0; i < _timelineLabels.length; i++) {
      final data = _timelineData[i]!;
      if (data.hasData) {
        compiledTimeline.add({
          'stage': _timelineLabels[i],
          'sideEffects': data.sideEffects,
          'severity': data.severity,
          'imageFile': data.image,
        });
      }
    }

    if (compiledTimeline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide timeline details for at least one stage.", style: TextStyle(color: Colors.white))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reportService.submitDangerousProductReport(
        productName: _productNameController.text.trim(),
        brand: _brandController.text.trim(),
        isAnonymous: _isAnonymous,
        timelineData: compiledTimeline,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: const Icon(Icons.security_rounded, color: Colors.teal, size: 56),
            title: const Text("Report Securely Submitted"),
            content: const Text(
              "Thank you. Your report has been encrypted and sent to our cosmetic safety experts for review. Your contribution helps keep the community safe.",
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text("Report Harmful Product", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Privacy Reassurance ---
            _buildPrivacyHeader(cs),
            const SizedBox(height: 16),

            // ✅ NEW: Entry point to view approved hazard reports
            _buildPublicDatabaseBanner(context, cs),
            const SizedBox(height: 24),

            // --- Product Identity ---
            Text("Product Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: "Product Name *",
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: "Brand / Manufacturer",
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- Experience Timeline ---
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text("Reaction Timeline", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4.0, bottom: 16.0),
              child: Text("Document your experience over time. Select a stage to add details.", style: TextStyle(color: Colors.grey)),
            ),
            _buildTimelineStepper(cs),
            const SizedBox(height: 24),

            // --- Step Specific Details (Updates when timeline is tapped) ---
            _buildStepDetailsCard(cs),
            const SizedBox(height: 32),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submitReport,
                icon: const Icon(Icons.shield_rounded),
                label: const Text("Submit Official Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ✅ NEW WIDGET: Banner to navigate to PublicHazardReportsScreen
  Widget _buildPublicDatabaseBanner(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PublicHazardReportsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo.shade100, shape: BoxShape.circle),
              child: Icon(Icons.manage_search_rounded, color: Colors.indigo.shade800),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Check known hazards", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                  Text("Browse reports verified by experts", style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.indigo.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade100, shape: BoxShape.circle),
                child: Icon(Icons.lock_person_rounded, color: Colors.teal.shade800),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Your privacy is strictly protected. Data is encrypted and only visible to verified medical experts.",
                  style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          SwitchListTile(
            title: const Text("Report Anonymously", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_isAnonymous ? "Your identity is hidden" : "Your ID will be visible to experts", style: const TextStyle(fontSize: 12)),
            value: _isAnonymous,
            activeColor: Colors.teal.shade700,
            onChanged: (v) => setState(() => _isAnonymous = v),
            contentPadding: EdgeInsets.zero,
          )
        ],
      ),
    );
  }

  Widget _buildTimelineStepper(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_timelineLabels.length, (index) {
          final isActive = index == _currentTimelineStep;
          // Check if this specific step has data (to show a completed checkmark)
          // We must check current text controller for the active step, and the map for others
          final stepHasData = isActive
              ? (_sideEffectsController.text.isNotEmpty || _timelineData[index]!.severity > 1.0 || _timelineData[index]!.image != null)
              : _timelineData[index]!.hasData;

          return GestureDetector(
            onTap: () => _changeTimelineStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.deepOrange.shade50 : cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? Colors.deepOrange : (stepHasData ? Colors.green.shade300 : cs.outlineVariant),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive ? [BoxShadow(color: Colors.deepOrange.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)] : [],
              ),
              child: Row(
                children: [
                  if (stepHasData && !isActive) ...[
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _timelineLabels[index],
                    style: TextStyle(
                      color: isActive ? Colors.deepOrange.shade800 : cs.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepDetailsCard(ColorScheme cs) {
    final currentData = _timelineData[_currentTimelineStep]!;

    return ModernCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
          color: Colors.orange.shade50.withOpacity(0.3),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _timelineLabels[_currentTimelineStep],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text("Observations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sideEffectsController,
              maxLines: 4,
              onChanged: (val) {
                // Trigger rebuild if it's the first character typed to update the checkmark in timeline
                if (val.length == 1 || val.isEmpty) setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Describe side effects (e.g., severe redness, peeling, hyperpigmentation...)",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Severity Scale", style: TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentData.severity > 3 ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Level ${currentData.severity.toInt()}",
                    style: TextStyle(
                      color: currentData.severity > 3 ? Colors.red.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: currentData.severity > 3 ? Colors.red.shade400 : Colors.orange.shade400,
                thumbColor: currentData.severity > 3 ? Colors.red : Colors.orange,
                overlayColor: (currentData.severity > 3 ? Colors.red : Colors.orange).withOpacity(0.2),
              ),
              child: Slider(
                value: currentData.severity,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => currentData.severity = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Mild", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Severe", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Using PhotoPickerCard and connecting the ImagePicker logic
            // File passed is specifically the image for the *current* timeline stage
            PhotoPickerCard(
              file: currentData.image,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}