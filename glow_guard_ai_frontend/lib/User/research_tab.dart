import 'package:flutter/material.dart';
import 'research_detail_screen.dart';

class ResearchTab extends StatelessWidget {
  const ResearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ("Mercury in cosmetics", "Why it is dangerous and how to avoid it."),
      ("Hydroquinone risks", "Skin irritation, safety guidance."),
      ("Steroids in creams", "Hidden steroid risks and symptoms."),
      ("Safe ingredients", "Niacinamide, ceramides, glycerin, etc."),
      ("How to read labels", "Fragrance, parabens, acids, preservatives."),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Research & Study")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (title, sub) = items[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            title: Text(title),
            subtitle: Text(sub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResearchDetailScreen(title: title, subtitle: sub),
              ),
            ),
          );
        },
      ),
    );
  }
}
