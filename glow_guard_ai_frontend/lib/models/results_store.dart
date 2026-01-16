import 'package:flutter/material.dart';
import 'test_models.dart';

final ValueNotifier<List<TestResult>> resultsStore =
    ValueNotifier<List<TestResult>>([]);

void addResult(TestResult r) {
  final list = List<TestResult>.from(resultsStore.value);
  list.insert(0, r);
  resultsStore.value = list;
}
