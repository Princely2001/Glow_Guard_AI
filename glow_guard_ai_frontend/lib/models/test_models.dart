enum TestType { mercury, hydroquinone, steroids }
enum TestOutcome { notDetected, detected, unclear }

String testTypeLabel(TestType t) {
  switch (t) {
    case TestType.mercury:
      return 'Mercury';
    case TestType.hydroquinone:
      return 'Hydroquinone';
    case TestType.steroids:
      return 'Steroids';
  }
}

String outcomeTitle(TestOutcome o) {
  switch (o) {
    case TestOutcome.detected:
      return 'Harmful Chemical Detected';
    case TestOutcome.notDetected:
      return 'No Harmful Chemical Detected';
    case TestOutcome.unclear:
      return 'Result Unclear';
  }
}

String outcomeSubtitle(TestOutcome o) {
  switch (o) {
    case TestOutcome.detected:
      return 'Stop using this product. Consider lab confirmation.';
    case TestOutcome.notDetected:
      return 'Preliminary screening only. Retest if unsure.';
    case TestOutcome.unclear:
      return 'Please retest with better lighting or seek a professional lab.';
  }
}

class TestResult {
  final String id;
  final DateTime time;
  final TestType type;
  final TestOutcome outcome;
  final int confidence;
  final String note;
  final String? beforePath;
  final String? afterPath;

  const TestResult({
    required this.id,
    required this.time,
    required this.type,
    required this.outcome,
    required this.confidence,
    required this.note,
    this.beforePath,
    this.afterPath,
  });
}
