import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/house_store.dart';
import '../data/notifications.dart';
import '../data/rotation.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/task_card.dart';
import 'privacy_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.store});

  final HouseStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.settings.myPersonId;
        final hours = [18, 19, 20, 21, 22];
        return ListView(
          padding: glassTabContentPadding,
          children: [
            Text(
              'House',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              store.cloudConnected
                  ? 'Live house board is on — when someone marks a job done, the others see it and get a ping.'
                  : 'This phone, rooms, and the 2× makeup rule. Connect to the internet so the house can share “done”.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  store.cloudConnected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: store.cloudConnected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(
                  store.cloudConnected ? 'Sharing with the house' : 'Offline',
                ),
                subtitle: Text(
                  store.cloudConnected
                      ? 'Checks sync to all 6 phones'
                      : (store.cloudError ?? 'Tap to retry joining the house board'),
                ),
                onTap: store.cloudConnected
                    ? null
                    : () async {
                        await store.cloudReconnect?.call();
                      },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Who uses this phone',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            PersonChips(
              store: store,
              selectedId: me,
              onSelected: (id) async {
                await store.saveSettings(
                  store.settings.copyWith(myPersonId: id),
                );
                await NotificationService.instance.resync(store);
              },
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            _NotificationCard(store: store),
            const SizedBox(height: 20),
            Text(
              'Night-before reminder',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final h in hours)
                  ChoiceChip(
                    label: Text('$h:00'),
                    selected: store.settings.notifyHour == h,
                    onSelected: (_) async {
                      await store.saveSettings(
                        store.settings.copyWith(notifyHour: h),
                      );
                      await NotificationService.instance.resync(store);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'People & rooms',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a name to edit it. Room 1 blue · 2 green · 3 orange.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final room in [1, 2, 3])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RoomBadge(roomId: room),
                            const SizedBox(width: 8),
                            Text(
                              store.namesForRoom(room),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        for (final person in store.peopleInRoom(room))
                          _PersonTile(store: store, person: person),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Penalties',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'No notice by end of the work day → that room owes 2×. The rotation dates never move.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            if (store.openDebts.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('No open makeups'),
                ),
              )
            else
              for (final debt in store.openDebts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roomFill(
                          debt.roomId,
                          Theme.of(context).brightness,
                        ),
                        child: Text(
                          'R${debt.roomId}',
                          style: TextStyle(
                            color: roomColor(debt.roomId),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        '${debt.jobType.title} · Room ${debt.roomId}',
                      ),
                      subtitle: Text(
                        'Missed ${debt.missedDate.day}/${debt.missedDate.month}/${debt.missedDate.year}'
                        ' · ${store.namesForRoom(debt.roomId)}',
                      ),
                    ),
                  ),
                ),
            if (store.openDebts.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: store.resetPenalties,
                  child: const Text('Clear open makeups'),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _share(store),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share next 2 weeks'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await store.scanPenalties();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        store.openDebts.isEmpty
                            ? 'No missed jobs without notice'
                            : '${store.openDebts.length} makeup(s) on the board',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.rule),
              label: const Text('Check missed jobs'),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Downstairs from 19 Aug 2026 (R1). Upstairs from 23 Aug 2026 (R3). Garbage: Mon–Tue R3, Wed–Thu R1, Fri–Sat R2, Sunday = upstairs room.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _share(HouseStore store) async {
    final today = dateOnly(DateTime.now());
    final buf = StringBuffer(
      '2A House — ${today.day}/${today.month}/${today.year}\n',
    );
    for (final day in daysInRange(today, addDays(today, 13))) {
      final jobs = store.occurrencesOn(day);
      if (jobs.isEmpty) continue;
      buf.writeln();
      buf.writeln('${_weekday(day.weekday)} ${day.day}/${day.month}');
      for (final j in jobs) {
        final tag = j.isMakeup ? 'MAKEUP ' : '';
        buf.writeln(
          '  $tag${j.jobType.title}: R${j.assignedRoom} (${store.namesForRoom(j.assignedRoom)})'
          '${j.completed ? ' ✓' : ''}',
        );
      }
    }
    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  String _weekday(int w) =>
      const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.store, required this.person});

  final HouseStore store;
  final Person person;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: roomFill(person.roomId, Theme.of(context).brightness),
        child: Text(
          person.name.characters.first,
          style: TextStyle(
            color: roomColor(person.roomId),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(person.name),
      trailing: DropdownButton<int>(
        value: person.roomId,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        items: const [
          DropdownMenuItem(value: 1, child: Text('R1')),
          DropdownMenuItem(value: 2, child: Text('R2')),
          DropdownMenuItem(value: 3, child: Text('R3')),
        ],
        onChanged: (room) {
          if (room == null) return;
          store.savePerson(person.copyWith(roomId: room));
        },
      ),
      onTap: () => _editName(context),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: person.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'First name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty) return;
    await store.savePerson(person.copyWith(name: next));
  }
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({required this.store});

  final HouseStore store;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  var _enabled = false;
  var _checked = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ok = await NotificationService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = ok;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _enabled
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: _enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !_checked
                        ? 'Checking reminders…'
                        : _enabled
                        ? 'Reminders are allowed'
                        : 'Reminders are off',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _enabled
                  ? 'This phone will ping the night before and at 9am on your room’s jobs.'
                  : Theme.of(context).platform == TargetPlatform.iOS
                  ? 'Tap Allow, then Allow on the iPhone prompt. If you said Don’t Allow, turn them on in Settings → 2A House → Notifications.'
                  : 'Tap Allow, then Allow on the system prompt.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await NotificationService.instance
                        .requestPermission();
                    if (!mounted) return;
                    setState(() => _enabled = ok);
                    if (ok) {
                      await NotificationService.instance.resync(widget.store);
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Still off — enable notifications for 2A House in Settings',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _enabled ? 'Asked already' : 'Allow notifications',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await NotificationService.instance
                        .requestPermission();
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Turn on notifications for 2A House in system settings first',
                          ),
                        ),
                      );
                      return;
                    }
                    await NotificationService.instance.showTest();
                  },
                  child: const Text('Send test ping'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
