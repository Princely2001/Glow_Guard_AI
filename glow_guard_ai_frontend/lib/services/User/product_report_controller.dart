import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'report_service.dart';

// Class to hold data for each specific timeline stage
class TimelineStepData {
  String sideEffects = "";
  double severity = 1.0;
  File? image;

  bool get hasData => sideEffects.isNotEmpty || severity > 1.0 || image != null;
}

class ProductReportController extends ChangeNotifier {
  // Services
  final ImagePicker _picker = ImagePicker();
  final ReportService _reportService = ReportService();

  // State Variables
  bool isAnonymous = true;
  int currentTimelineStep = 0;
  bool isLoading = false;

  // Controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController sideEffectsController = TextEditingController();

  final List<String> timelineLabels = [
    "First 3 Days", "First Week", "Second Week", "Third Week", "One Month", "Three Months"
  ];

  // Map to hold individual data for each timeline step
  final Map<int, TimelineStepData> timelineData = {};

  ProductReportController() {
    // Initialize data storage for each step
    for (int i = 0; i < timelineLabels.length; i++) {
      timelineData[i] = TimelineStepData();
    }
  }

  void toggleAnonymous(bool value) {
    isAnonymous = value;
    notifyListeners();
  }

  void updateSeverity(double value) {
    timelineData[currentTimelineStep]!.severity = value;
    notifyListeners();
  }

  // --- UI Logic: Switching Steps ---
  void changeTimelineStep(int index) {
    // Save current step's text data before switching
    timelineData[currentTimelineStep]!.sideEffects = sideEffectsController.text;

    currentTimelineStep = index;
    // Load the new step's text data
    sideEffectsController.text = timelineData[index]!.sideEffects;

    notifyListeners();
  }

  // Used by the UI to trigger rebuilds when typing
  void notifyTyping() {
    notifyListeners();
  }

  // --- Image Picking Logic ---
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        timelineData[currentTimelineStep]!.image = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      throw Exception("Failed to pick image: $e");
    }
  }

  // --- Submission Logic ---
  Future<bool> submitReport() async {
    if (productNameController.text.trim().isEmpty) {
      throw Exception("Please enter the product name.");
    }

    // Save the text of the currently active step
    timelineData[currentTimelineStep]!.sideEffects = sideEffectsController.text.trim();

    // Compile timeline data that actually has user input
    List<Map<String, dynamic>> compiledTimeline = [];
    for (int i = 0; i < timelineLabels.length; i++) {
      final data = timelineData[i]!;
      if (data.hasData) {
        compiledTimeline.add({
          'stage': timelineLabels[i],
          'sideEffects': data.sideEffects,
          'severity': data.severity,
          'imageFile': data.image,
        });
      }
    }

    if (compiledTimeline.isEmpty) {
      throw Exception("Please provide timeline details for at least one stage.");
    }

    isLoading = true;
    notifyListeners();

    try {
      await _reportService.submitDangerousProductReport(
        productName: productNameController.text.trim(),
        brand: brandController.text.trim(),
        isAnonymous: isAnonymous,
        timelineData: compiledTimeline,
      );

      isLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      isLoading = false;
      notifyListeners();
      throw Exception(e.toString());
    }
  }

  @override
  void dispose() {
    productNameController.dispose();
    brandController.dispose();
    sideEffectsController.dispose();
    super.dispose();
  }
}