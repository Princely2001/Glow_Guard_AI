import 'package:flutter/material.dart';
import 'user_store.dart';

class RequestTestScreen extends StatefulWidget {
  final Expert expert;
  const RequestTestScreen({super.key, required this.expert});

  @override
  State<RequestTestScreen> createState() => _RequestTestScreenState();
}

class _RequestTestScreenState extends State<RequestTestScreen> {
  final _product = TextEditingController();
  final _note = TextEditingController();
  TestType _type = TestType.mercury;

  @override
  void dispose() {
    _product.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (_product.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter product name.")),
      );
      return;
    }

    createUserRequest(
      expert: widget.expert,
      productName: _product.text.trim(),
      type: _type,
      note: _note.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request sent (design-only).")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Request Chemical Test")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Expert", style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text("${widget.expert.name} • ${widget.expert.specialty}",
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _product,
            decoration: InputDecoration(
              labelText: "Product name",
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),

          Text("Select test type", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TestType.values.map((t) {
              return ChoiceChip(
                selected: _type == t,
                label: Text(testTypeLabel(t)),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _note,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Notes (optional)",
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.65),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send_outlined),
            label: const Text("Send Request"),
          ),
        ],
      ),
    );
  }
}
