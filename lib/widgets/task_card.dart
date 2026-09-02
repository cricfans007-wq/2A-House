import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/house_store.dart';
import '../models.dart';
import '../theme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.store,
    required this.occurrence,
    this.compact = false,
  });

  final HouseStore store;
  final Occurrence occurrence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = roomColor(occurrence.assignedRoom, store.house);
    final names = store.namesForRoom(occurrence.assignedRoom);
    final scheme = Theme.of(context).colorScheme;
    final mine = store.me?.roomId == occurrence.assignedRoom;
    final canNotify = store.canNotify(occurrence.date);
    final done = occurrence.completed;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: done ? 0.62 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: mine && !done
            ? roomFill(
                occurrence.assignedRoom,
                Theme.of(context).brightness,
                store.house,
              )
            : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              occurrence.jobType.icon,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  occurrence.isMakeup
                                      ? 'Makeup · ${store.jobTitle(occurrence.jobType)}'
                                      : store.jobTitle(occurrence.jobType),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${store.house.roomLabel(occurrence.assignedRoom)} · $names',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (occurrence.notifiedOnTime && !done)
                                  Text(
                                    '${store.personById(occurrence.notifiedById)?.name ?? 'Someone'} told the house',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                if (done)
                                  Text(
                                    'Done by ${store.personById(occurrence.completedById)?.name ?? 'the house'}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          _DoneButton(
                            done: done,
                            color: color,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              store.saveOccurrence(
                                occurrence.copyWith(
                                  completed: v,
                                  completedAt: v ? DateTime.now() : null,
                                  completedById: store.settings.myPersonId,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (mine)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _Pill(label: 'Your room', color: color),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        occurrence.isMakeup && occurrence.missedDate != null
                            ? 'Missed ${DateFormat('d MMM').format(occurrence.missedDate!)}'
                            : store.jobBlurb(occurrence.jobType),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 10),
                        for (final item in store.jobChecklist(
                          occurrence.jobType,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_rounded
                                      : Icons.circle_outlined,
                                  size: 14,
                                  color: done ? color : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed:
                                  !canNotify && !occurrence.notifiedOnTime
                                  ? null
                                  : () => _toggleNotify(context),
                              icon: Icon(
                                occurrence.notifiedOnTime
                                    ? Icons.notifications_active
                                    : Icons.campaign_outlined,
                                size: 18,
                              ),
                              label: Text(
                                occurrence.notifiedOnTime
                                    ? 'Notified'
                                    : 'Notify house',
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              tooltip: 'Swap room',
                              icon: const Icon(Icons.swap_horiz),
                              onSelected: (value) {
                                final room = int.parse(value);
                                store.saveOccurrence(
                                  occurrence.copyWith(assignedRoom: room),
                                );
                              },
                              itemBuilder: (context) => [
                                for (final room in store.house.rooms)
                                  PopupMenuItem(
                                    value: '${room.id}',
                                    enabled: room.id != occurrence.assignedRoom,
                                    child: Text(
                                      'Give to ${room.name} (${store.namesForRoom(room.id)})',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNotify(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final next = !occurrence.notifiedOnTime;
    await store.saveOccurrence(
      occurrence.copyWith(
        notifiedOnTime: next,
        notifiedAt: next ? DateTime.now() : null,
        notifiedById: next ? store.settings.myPersonId : null,
        clearNotified: !next,
      ),
    );
    if (!next) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          store.cloudConnected
              ? 'House pinged — no 2× if they cover or swap'
              : 'Saved here. Turn on data so the others get the ping.',
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.done,
    required this.color,
    required this.onChanged,
  });

  final bool done;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: done ? 'Mark not done' : 'Mark done',
      onPressed: () => onChanged(!done),
      icon: Icon(
        done ? Icons.check_circle : Icons.circle_outlined,
        color: done ? color : Theme.of(context).colorScheme.outline,
        size: 30,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class RoomBadge extends StatelessWidget {
  const RoomBadge({
    super.key,
    required this.roomId,
    this.small = false,
    this.house,
  });

  final int roomId;
  final bool small;
  final HouseProfile? house;

  @override
  Widget build(BuildContext context) {
    final color = roomColor(roomId, house);
    final label = house?.roomById(roomId)?.name ?? 'R$roomId';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: roomFill(roomId, Theme.of(context).brightness, house),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: small ? 11 : 13,
        ),
      ),
    );
  }
}

class PersonChips extends StatelessWidget {
  const PersonChips({
    super.key,
    required this.store,
    required this.selectedId,
    required this.onSelected,
  });

  final HouseStore store;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in store.people)
          ChoiceChip(
            selected: p.id == selectedId,
            showCheckmark: false,
            avatar: CircleAvatar(
              backgroundColor: roomFill(
                p.roomId,
                Theme.of(context).brightness,
                store.house,
              ),
              child: Text(
                p.name.characters.first,
                style: TextStyle(
                  color: roomColor(p.roomId, store.house),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            label: Text('${p.name}  R${p.roomId}'),
            onSelected: (_) => onSelected(p.id),
          ),
      ],
    );
  }
}
