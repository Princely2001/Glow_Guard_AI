import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Instructions & Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step-by-step',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                const StepRow(n: 1, title: 'Prepare test kit', subtitle: 'Read kit instructions and wear gloves if available.'),
                const StepRow(n: 2, title: 'Take “Before” photo', subtitle: 'Plain background, steady hand, good lighting.'),
                const StepRow(n: 3, title: 'Apply reagent / strip', subtitle: 'Avoid skin contact. Keep children away.'),
                const StepRow(n: 4, title: 'Wait for color change', subtitle: 'Follow the kit time exactly.'),
                const StepRow(n: 5, title: 'Take “After” photo', subtitle: 'Same angle + lighting as “Before”.'),
                const StepRow(n: 6, title: 'Analyze in app', subtitle: 'Upload both photos and view results.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: cs.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Safety: This is a screening tool. If your result is Detected/Unclear, consider professional lab testing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSecondaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
