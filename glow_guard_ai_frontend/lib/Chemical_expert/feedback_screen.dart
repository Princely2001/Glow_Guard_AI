import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit feedback (Design Only)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Product name (optional)',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Your feedback',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Feedback submitted (design only).')),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
