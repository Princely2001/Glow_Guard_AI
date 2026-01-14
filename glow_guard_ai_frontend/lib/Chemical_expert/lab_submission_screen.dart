import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class LabSubmissionScreen extends StatelessWidget {
  const LabSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Referral')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit to a professional lab (Design Only)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Use this when results are Detected or Unclear.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Your email',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Product details (optional)',
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
                        content: Text('Lab referral sent (design only).')),
                  ),
                  icon: const Icon(Icons.science_outlined),
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
