import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/common_widgets.dart';
import '../services/User/report_service.dart'; // Import the new service

class DangerousProductReportScreen extends StatefulWidget {
  const DangerousProductReportScreen({super.key});

  @override
  State<DangerousProductReportScreen> createState() => _DangerousProductReportScreenState();
}

class _DangerousProductReportScreenState extends State<DangerousProductReportScreen> {
  // State Variables
  bool _isAnonymous = true;
  int _currentTimelineStep = 0;
  double _severityLevel = 3.0;
  bool _isLoading = false;
  File? _selectedImage;

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

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress slightly to save storage space
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
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
    // Basic Validation
    if (_productNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the product name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reportService.submitDangerousProductReport(
        productName: _productNameController.text.trim(),
        brand: _brandController.text.trim(),
        isAnonymous: _isAnonymous,
        timelineLabel: _timelineLabels[_currentTimelineStep],
        sideEffects: _sideEffectsController.text.trim(),
        severity: _severityLevel,
        imageFile: _selectedImage,
      );

      if (mounted) {
        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            title: const Text("Report Submitted"),
            content: const Text("Thank you. Your report has been securely sent to our experts for review to help keep the community safe."),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to Home Tab
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
      appBar: AppBar(
        title: const Text("Report Harmful Product"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Privacy Reassurance ---
            _buildPrivacyHeader(cs),
            const SizedBox(height: 20),

            // --- Product Identity ---
            Text("Product Details", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ModernCard(
              child: Column(
                children: [
                  TextField(
                    controller: _productNameController,
                    decoration: const InputDecoration(labelText: "Product Name *", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: "Brand / Manufacturer", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Experience Timeline ---
            Row(
              children: [
                Text("Reaction Timeline", style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Icon(Icons.history_toggle_off, color: cs.primary),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimelineStepper(cs),
            const SizedBox(height: 24),

            // --- Severity & Description ---
            _buildStepDetailsCard(cs),
            const SizedBox(height: 32),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submitReport,
                icon: const Icon(Icons.send_rounded),
                label: const Text("Submit Official Report"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: cs.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text("Your privacy is our priority. Reports are encrypted and verified by experts.")),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text("Report Anonymously"),
            subtitle: Text(_isAnonymous ? "Your identity is hidden" : "Your ID will be visible to experts"),
            value: _isAnonymous,
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
      child: Row(
        children: List.generate(_timelineLabels.length, (index) {
          final isActive = index == _currentTimelineStep;
          return GestureDetector(
            onTap: () => setState(() => _currentTimelineStep = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? cs.primary : cs.outlineVariant),
              ),
              child: Text(
                _timelineLabels[index],
                style: TextStyle(color: isActive ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepDetailsCard(ColorScheme cs) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Observation: ${_timelineLabels[_currentTimelineStep]}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _sideEffectsController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Describe side effects (e.g., severe redness, peeling, hyperpigmentation...)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text("Severity Scale: Level ${_severityLevel.toInt()}"),
          Slider(
            value: _severityLevel,
            min: 1,
            max: 5,
            divisions: 4,
            label: "Level ${_severityLevel.toInt()}",
            activeColor: Colors.orange.shade600,
            onChanged: (v) => setState(() => _severityLevel = v),
          ),
          const SizedBox(height: 16),
          // Using PhotoPickerCard and connecting the ImagePicker logic
          PhotoPickerCard(
            file: _selectedImage,
            onCamera: () => _pickImage(ImageSource.camera),
            onGallery: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}