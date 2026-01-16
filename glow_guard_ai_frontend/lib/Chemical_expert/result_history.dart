import 'package:flutter/material.dart';

import '../models/results_store.dart';
import '../models/test_models.dart';
import '../widgets/common_widgets.dart';



class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ValueListenableBuilder<List<TestResult>>(
        valueListenable: resultsStore,
        builder: (context, results, _) {
          if (results.isEmpty) {
            return const Center(child: Text('No saved results yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = results[i];
              return ResultTile(
                result: r,
                onTap: () => Navigator.push(
                  context,
                  //MaterialPageRoute(builder: (_) => ResultScreen(result: r)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
