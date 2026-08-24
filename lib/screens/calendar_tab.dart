import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/house_store.dart';
import '../data/rotation.dart';
import '../theme.dart';
import '../widgets/task_card.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key, required this.store});

  final HouseStore store;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _focused;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _focused = dateOnly(DateTime.now());
    _selected = _focused;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final selected = _selected ?? _focused;
        final jobs = store.occurrencesOn(selected);
        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: glassTabContentPadding,
          children: [
            Text(
              'Who’s on',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Downstairs R1→R2→R3 · Upstairs R3→R2→R1',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final room in [1, 2, 3]) ...[
                  RoomBadge(roomId: room, small: true),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      store.namesForRoom(room).split(' & ').first,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  if (room != 3) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TableCalendar(
                  firstDay: DateTime(2026, 8, 1),
                  lastDay: DateTime(2027, 12, 31),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => isSameDay(d, _selected),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: scheme.onSurface),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final rooms =
                          store
                              .occurrencesOn(day)
                              .map((o) => o.assignedRoom)
                              .toSet()
                              .toList()
                            ..sort();
                      if (rooms.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final r in rooms)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: roomColor(r),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selected = dateOnly(selectedDay);
                      _focused = focusedDay;
                    });
                  },
                  onPageChanged: (focused) => _focused = focused,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE d MMMM').format(selected),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (jobs.isEmpty)
              Text(
                'No assignments this day.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final occ in jobs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskCard(store: store, occurrence: occ),
                ),
          ],
        );
      },
    );
  }
}
