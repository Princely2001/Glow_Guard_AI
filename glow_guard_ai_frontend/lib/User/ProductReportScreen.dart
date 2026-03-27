import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/common_widgets.dart';
import 'public_hazard_reports_screen.dart';
import '../services/User/product_report_controller.dart'; // Import the new controller

class DangerousProductReportScreen extends StatefulWidget {
  const DangerousProductReportScreen({super.key});

  @override
  State<DangerousProductReportScreen> createState() => _DangerousProductReportScreenState();
}

class _DangerousProductReportScreenState extends State<DangerousProductReportScreen> {
  late final ProductReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductReportController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleImagePick(ImageSource source) async {
    try {
      await _controller.pickImage(source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _handleSubmit() async {
    try {
      final success = await _controller.submitReport();
      if (success && mounted) {
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
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", ""), style: const TextStyle(color: Colors.white)),
          ),
        );
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
      body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyHeader(cs),
                  const SizedBox(height: 16),
                  _buildPublicDatabaseBanner(context, cs),
                  const SizedBox(height: 24),

                  Text("Product Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _controller.productNameController,
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
                            controller: _controller.brandController,
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

                  _buildStepDetailsCard(cs),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _handleSubmit,
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
            );
          }
      ),
    );
  }

  Widget _buildPublicDatabaseBanner(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicHazardReportsScreen()));
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
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider()),
          SwitchListTile(
            title: const Text("Report Anonymously", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_controller.isAnonymous ? "Your identity is hidden" : "Your ID will be visible to experts", style: const TextStyle(fontSize: 12)),
            value: _controller.isAnonymous,
            activeColor: Colors.teal.shade700,
            onChanged: _controller.toggleAnonymous,
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
        children: List.generate(_controller.timelineLabels.length, (index) {
          final isActive = index == _controller.currentTimelineStep;
          final stepData = _controller.timelineData[index]!;

          final stepHasData = isActive
              ? (_controller.sideEffectsController.text.isNotEmpty || stepData.severity > 1.0 || stepData.image != null)
              : stepData.hasData;

          return GestureDetector(
            onTap: () => _controller.changeTimelineStep(index),
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
                    _controller.timelineLabels[index],
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
    final currentData = _controller.timelineData[_controller.currentTimelineStep]!;

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
                  decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _controller.timelineLabels[_controller.currentTimelineStep],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text("Observations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller.sideEffectsController,
              maxLines: 4,
              onChanged: (val) {
                if (val.length == 1 || val.isEmpty) _controller.notifyTyping();
              },
              decoration: InputDecoration(
                hintText: "Describe side effects (e.g., severe redness, peeling, hyperpigmentation...)",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                onChanged: _controller.updateSeverity,
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
            PhotoPickerCard(
              file: currentData.image,
              onCamera: () => _handleImagePick(ImageSource.camera),
              onGallery: () => _handleImagePick(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}