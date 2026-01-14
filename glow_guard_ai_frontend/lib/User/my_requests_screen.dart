import 'package:flutter/material.dart';
import 'user_store.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: ValueListenableBuilder(
        valueListenable: userRequestsStore,
        builder: (context, List<UserTestRequest> list, _) {
          if (list.isEmpty) {
            return const Center(child: Text("No requests yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = list[i];
              final status = r.status.name;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${r.productName} • ${r.expertName}",
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      "Type: ${testTypeLabel(r.testType)} • Status: $status",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    if (r.status == RequestStatus.completed && r.resultSummary != null)
                      FilledButton.icon(
                        onPressed: () {
                          // Later: navigate to your real Result screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Result: ${r.resultSummary}")),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text("View Result"),
                      )
                    else
                      Text(
                        "Waiting for expert to complete the test.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
