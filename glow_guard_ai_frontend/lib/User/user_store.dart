import 'package:flutter/material.dart';

enum TestType { mercury, hydroquinone, steroids }
enum RequestStatus { pending, inProgress, completed }

String testTypeLabel(TestType t) => switch (t) {
      TestType.mercury => "Mercury",
      TestType.hydroquinone => "Hydroquinone",
      TestType.steroids => "Steroids",
    };

class Expert {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int jobs;

  const Expert({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.jobs,
  });
}

class UserTestRequest {
  final String id;
  final DateTime createdAt;
  final String productName;
  final TestType testType;
  final String note;

  final String expertId;
  final String expertName;

  final RequestStatus status;

  // design-only placeholders for expert-uploaded proof/result
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? resultSummary; // e.g. "Detected Mercury (85%)"

  const UserTestRequest({
    required this.id,
    required this.createdAt,
    required this.productName,
    required this.testType,
    required this.note,
    required this.expertId,
    required this.expertName,
    required this.status,
    this.beforeImagePath,
    this.afterImagePath,
    this.resultSummary,
  });

  UserTestRequest copyWith({
    RequestStatus? status,
    String? beforeImagePath,
    String? afterImagePath,
    String? resultSummary,
  }) {
    return UserTestRequest(
      id: id,
      createdAt: createdAt,
      productName: productName,
      testType: testType,
      note: note,
      expertId: expertId,
      expertName: expertName,
      status: status ?? this.status,
      beforeImagePath: beforeImagePath ?? this.beforeImagePath,
      afterImagePath: afterImagePath ?? this.afterImagePath,
      resultSummary: resultSummary ?? this.resultSummary,
    );
  }
}

// --------- Demo experts (UI only) ----------
final expertsStore = ValueNotifier<List<Expert>>([
  const Expert(
    id: "e1",
    name: "Dr. N. Perera",
    specialty: "Cosmetic Chemist",
    rating: 4.8,
    jobs: 132,
  ),
  const Expert(
    id: "e2",
    name: "Ms. A. Fernando",
    specialty: "Analytical Chemist",
    rating: 4.6,
    jobs: 98,
  ),
  const Expert(
    id: "e3",
    name: "Mr. S. Jayasuriya",
    specialty: "Quality Control Specialist",
    rating: 4.7,
    jobs: 110,
  ),
]);

// --------- User requests (UI only) ----------
final userRequestsStore = ValueNotifier<List<UserTestRequest>>([]);

void createUserRequest({
  required Expert expert,
  required String productName,
  required TestType type,
  required String note,
}) {
  final r = UserTestRequest(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
    productName: productName,
    testType: type,
    note: note,
    expertId: expert.id,
    expertName: expert.name,
    status: RequestStatus.pending,
  );
  final list = List<UserTestRequest>.from(userRequestsStore.value);
  list.insert(0, r);
  userRequestsStore.value = list;
}
