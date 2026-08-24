import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/house_store.dart';
import '../data/rotation.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/task_card.dart';

class WeekTab extends StatefulWidget {
  const WeekTab({super.key, required this.store});

  final HouseStore store;

  @override
  State<WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends State<WeekTab> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => _buildWeek(context),
    );
  }

  Widget _buildWeek(BuildContext context) {
    final store = widget.store;
    final today = dateOnly(DateTime.now());
    final monday = startOfWeek(today);
    final days = List.generate(7, (i) => addDays(monday, i));
    final me = store.me;
    final jobs = store.occurrencesOn(_selected);
    final mine = jobs
        .where((o) => me != null && o.assignedRoom == me.roomId)
        .toList();
    final others = jobs
        .where((o) => me == null || o.assignedRoom != me.roomId)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headline(today, me),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  me == null
                      ? 'Pick yourself in House so we can highlight your jobs.'
                      : mine.isEmpty && _selected == today
                      ? 'You’re off today — nothing for Room ${me.roomId}.'
                      : mine.isNotEmpty && _selected == today
                      ? 'Room ${me.roomId} is on. Mark done when it’s finished.'
                      : DateFormat('EEEE d MMMM').format(_selected),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                _WeekStrip(
                  days: days,
                  today: today,
                  selected: _selected,
                  store: store,
                  myRoom: me?.roomId,
                  onSelect: (d) => setState(() => _selected = d),
                ),
                if (store.openDebts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DebtBanner(store: store),
                ],
                const SizedBox(height: 18),
                Text(
                  _selected == today
                      ? 'Today'
                      : DateFormat('EEEE d').format(_selected),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          sliver: SliverList.list(
            children: [
              if (jobs.isEmpty)
                const _QuietState(
                  icon: Icons.weekend_outlined,
                  title: 'Nothing on this day',
                  body: 'No downstairs, upstairs, or garbage.',
                )
              else ...[
                if (mine.isNotEmpty) ...[
                  for (final occ in mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(store: store, occurrence: occ),
                    ),
                ],
                if (others.isNotEmpty) ...[
                  if (mine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                      child: Text(
                        'Rest of the house',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final occ in others)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(store: store, occurrence: occ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _headline(DateTime today, Person? me) {
    if (_selected != today) {
      return DateFormat('EEEE d MMM').format(_selected);
    }
    if (me == null) return 'This week';
    return 'Hey ${me.name.split(' ').first}';
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.today,
    required this.selected,
    required this.store,
    required this.onSelect,
    this.myRoom,
  });

  final List<DateTime> days;
  final DateTime today;
  final DateTime selected;
  final HouseStore store;
  final int? myRoom;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayCell(
                day: day,
                isToday: day == today,
                isSelected: day == selected,
                mine:
                    myRoom != null &&
                    store
                        .occurrencesOn(day)
                        .any((o) => o.assignedRoom == myRoom),
                rooms:
                    store
                        .occurrencesOn(day)
                        .map((o) => o.assignedRoom)
                        .toSet()
                        .toList()
                      ..sort(),
                onTap: () => onSelect(day),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.mine,
    required this.rooms,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool mine;
  final List<int> rooms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? scheme.primary
          : isToday
          ? scheme.primary.withValues(alpha: 0.12)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day).substring(0, 1),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (rooms.isEmpty)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: (isSelected ? scheme.onPrimary : scheme.outline)
                            .withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    for (final r in rooms.take(3))
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? scheme.onPrimary : roomColor(r),
                          shape: BoxShape.circle,
                        ),
                      ),
                ],
              ),
              if (mine && !isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtBanner extends StatelessWidget {
  const _DebtBanner({required this.store});

  final HouseStore store;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB45309).withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.replay_circle_filled, color: Color(0xFFB45309)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${store.openDebts.length} makeup${store.openDebts.length == 1 ? '' : 's'} owed — missed with no notice',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietState extends StatelessWidget {
  const _QuietState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
