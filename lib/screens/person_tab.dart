import 'package:flutter/material.dart';

import '../data/house_store.dart';
import '../theme.dart';
import '../widgets/task_card.dart';

class PersonTab extends StatefulWidget {
  const PersonTab({super.key, required this.store});

  final HouseStore store;

  @override
  State<PersonTab> createState() => _PersonTabState();
}

class _PersonTabState extends State<PersonTab> {
  String? _personId;

  @override
  void initState() {
    super.initState();
    final people = widget.store.people;
    _personId =
        widget.store.settings.myPersonId ??
        (people.isEmpty ? null : people.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final people = store.people;
        if (people.isEmpty) {
          return ListView(
            padding: glassTabContentPadding,
            children: const [Text('Add people in House first.')],
          );
        }
        final person = store.personById(_personId) ?? people.first;
        final tasks = store.upcomingForPerson(person);
        final penalties = store.openDebtsForRoom(person.roomId);
        final upcoming = store.hasUpcomingBadge(person);

        return ListView(
          padding: glassTabContentPadding,
          children: [
            Text(
              person.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                RoomBadge(roomId: person.roomId, house: store.house),
                const SizedBox(width: 8),
                Text(
                  store.namesForRoom(person.roomId),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PersonChips(
              store: store,
              selectedId: person.id,
              onSelected: (id) => setState(() => _personId = id),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Makeups',
                    value: '${penalties.length}',
                    hint: penalties.isEmpty
                        ? 'Room is clear'
                        : '2× after a no-show',
                    alert: penalties.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Next 14 days',
                    value: '${tasks.length}',
                    hint: upcoming ? 'On today or tomorrow' : 'Nothing in 48h',
                    alert: upcoming,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Coming up',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Nothing for ${person.name} in the next two weeks.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final occ in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskCard(store: store, occurrence: occ),
                ),
            if (penalties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Open makeups',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final debt in penalties)
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.replay,
                      color: roomColor(debt.roomId, store.house),
                    ),
                    title: Text('${store.jobTitle(debt.jobType)} makeup'),
                    subtitle: Text(
                      'Missed ${debt.missedDate.day}/${debt.missedDate.month}/${debt.missedDate.year}',
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    this.alert = false,
  });

  final String label;
  final String value;
  final String hint;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: alert
                    ? const Color(0xFFB45309)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
