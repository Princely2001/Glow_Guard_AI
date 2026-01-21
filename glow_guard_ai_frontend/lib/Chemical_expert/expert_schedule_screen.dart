import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/Chemical_expert/expert_schedule_service.dart';
import 'expert_appointments_screen.dart';

class ExpertScheduleScreen extends StatefulWidget {
  const ExpertScheduleScreen({super.key});

  @override
  State<ExpertScheduleScreen> createState() => _ExpertScheduleScreenState();
}

class _ExpertScheduleScreenState extends State<ExpertScheduleScreen> {
  final _service = ExpertScheduleService();

  bool _loading = false;

  // ✅ Next 30 days (including today)
  late final List<DateTime> _days = List.generate(30, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  int _dayIndex = 0;
  DateTime get _selectedDate => _days[_dayIndex];

  // ✅ time slots
  final List<String> _allSlots = const [
    "09:00", "09:30",
    "10:00", "10:30",
    "11:00", "11:30",
    "13:00", "13:30",
    "14:00", "14:30",
    "15:00", "15:30",
    "16:00", "16:30",
    "17:00",
  ];

  final Set<String> _selectedSlots = <String>{};

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _loadDay(DateTime d) async {
    setState(() {
      _loading = true;
      _selectedSlots.clear();
    });

    try {
      final existing = await _service.getAvailabilitySlots(d);
      if (!mounted) return;
      setState(() => _selectedSlots.addAll(existing));
    } catch (e) {
      _snack("Failed to load availability: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedSlots.isEmpty) {
      _snack("Select at least 1 time slot.");
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.setAvailability(
        date: _selectedDate,
        slots: _selectedSlots.toList()..sort(),
      );
      _snack("Availability saved ✅");
      // ✅ reload to ensure UI matches database
      await _loadDay(_selectedDate);
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearDay() async {
    setState(() => _loading = true);
    try {
      await _service.clearAvailability(date: _selectedDate);
      if (!mounted) return;
      setState(() => _selectedSlots.clear());
      _snack("Cleared ✅");
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDay(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = DateFormat("EEE, MMM d").format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Availability"),
        actions: [
          IconButton(
            tooltip: "Appointments",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertAppointmentsScreen()),
              );
            },
            icon: const Icon(Icons.event_note_outlined),
          ),
          IconButton(
            tooltip: "Clear this day",
            onPressed: _loading ? null : _clearDay,
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
          // ✅ Header card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withOpacity(0.92),
                  cs.secondaryContainer.withOpacity(0.60),
                ],
              ),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.06),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary,
                  child: Icon(Icons.calendar_month_outlined, color: cs.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected day",
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Set your available time slots for the next 30 days.",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text("Pick a day", style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ 30-day date chips
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _days[i];
                final isSelected = i == _dayIndex;
                final label = DateFormat("MMM d").format(d);

                return ChoiceChip(
                  selected: isSelected,
                  label: Text(label),
                  onSelected: _loading
                      ? null
                      : (_) async {
                    setState(() => _dayIndex = i);
                    await _loadDay(_selectedDate);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Text("Time slots", style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withOpacity(0.22)),
                ),
                child: Text(
                  "${_selectedSlots.length} selected",
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ slots
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.55),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allSlots.map((slot) {
                final selected = _selectedSlots.contains(slot);
                return FilterChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: _loading
                      ? null
                      : (v) {
                    setState(() {
                      if (v) {
                        _selectedSlots.add(slot);
                      } else {
                        _selectedSlots.remove(slot);
                      }
                    });
                  },
                  showCheckmark: false,
                  avatar: selected
                      ? Icon(Icons.check_circle, size: 18, color: cs.primary)
                      : const Icon(Icons.access_time, size: 18),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save_outlined),
            label: const Text("Save Availability"),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "When you add future slots, users can book appointments.",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
