import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/house_store.dart';
import '../data/house_sync.dart';
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
                      ? 'Checks sync to every phone in this house'
                      : (store.cloudError ??
                            'Tap to retry joining the house board'),
                ),
                onTap: store.cloudConnected
                    ? null
                    : () async {
                        await store.cloudReconnect?.call();
                      },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(
                  store.settings.inviteCode ?? store.house.inviteCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                subtitle: const Text(
                  'Invite code — other phones join with this',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final code =
                        store.settings.inviteCode ?? store.house.inviteCode;
                    await SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Join ${store.house.name} in the House chores app. Code: $code',
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(store.house.name),
                subtitle: const Text('House name'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editHouseName(context, store),
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
              'Tap a name to edit it. Add rooms and people for your house.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final room in store.house.rooms)
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
                            RoomBadge(roomId: room.id, house: store.house),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                store.namesForRoom(room.id),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Rename room',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  _editRoomName(context, store, room),
                            ),
                          ],
                        ),
                        for (final person in store.peopleInRoom(room.id))
                          _PersonTile(store: store, person: person),
                      ],
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _addPerson(context, store),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add person'),
                ),
                TextButton.icon(
                  onPressed: store.house.rooms.length >= 8
                      ? null
                      : () => _addRoom(store),
                  icon: const Icon(Icons.add),
                  label: const Text('Add room'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Chore rules',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final type in JobType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JobRuleTile(store: store, type: type),
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
                          store.house,
                        ),
                        child: Text(
                          'R${debt.roomId}',
                          style: TextStyle(
                            color: roomColor(debt.roomId, store.house),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        '${store.jobTitle(debt.jobType)} · ${store.house.roomLabel(debt.roomId)}',
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
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave this house?'),
                    content: const Text(
                      'This phone will stop sharing the board. Rejoin with the invite code.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await store.leaveHouse();
              },
              child: const Text('Leave house'),
            ),
            const SizedBox(height: 20),
            Text(
              store.house.rulesSummary(),
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
      '${store.house.name} — ${today.day}/${today.month}/${today.year}\n',
    );
    for (final day in daysInRange(today, addDays(today, 13))) {
      final jobs = store.occurrencesOn(day);
      if (jobs.isEmpty) continue;
      buf.writeln();
      buf.writeln('${_weekday(day.weekday)} ${day.day}/${day.month}');
      for (final j in jobs) {
        final tag = j.isMakeup ? 'MAKEUP ' : '';
        buf.writeln(
          '  $tag${store.jobTitle(j.jobType)}: ${store.house.roomLabel(j.assignedRoom)} (${store.namesForRoom(j.assignedRoom)})'
          '${j.completed ? ' ✓' : ''}',
        );
      }
    }
    await SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  String _weekday(int w) =>
      const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];

  Future<void> _editHouseName(BuildContext context, HouseStore store) async {
    final next = await _prompt(
      context,
      title: 'House name',
      initial: store.house.name,
    );
    if (next == null || next.isEmpty) return;
    final name = next.length > 40 ? next.substring(0, 40) : next;
    await store.saveHouse(store.house.copyWith(name: name));
  }

  Future<void> _editRoomName(
    BuildContext context,
    HouseStore store,
    HouseRoom room,
  ) async {
    final next = await _prompt(context, title: 'Room name', initial: room.name);
    if (next == null || next.isEmpty) return;
    await store.saveHouse(
      store.house.copyWith(
        rooms: store.house.rooms
            .map((r) => r.id == room.id ? r.copyWith(name: next) : r)
            .toList(),
      ),
    );
  }

  Future<void> _addRoom(HouseStore store) async {
    final nextId =
        store.house.rooms.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;
    final rooms = [
      ...store.house.rooms,
      HouseRoom(
        id: nextId,
        name: 'Room $nextId',
        colorValue: roomPalette[(nextId - 1) % roomPalette.length],
      ),
    ];
    final rules = {
      for (final type in JobType.values)
        type: store.house
            .rule(type)
            .copyWith(
              cycle: store.house.rule(type).cycle.contains(nextId)
                  ? store.house.rule(type).cycle
                  : [...store.house.rule(type).cycle, nextId],
            ),
    };
    await store.saveHouse(store.house.copyWith(rooms: rooms, rules: rules));
  }

  Future<void> _addPerson(BuildContext context, HouseStore store) async {
    final next = await _prompt(context, title: 'First name', initial: '');
    if (next == null || next.isEmpty) return;
    await store.savePerson(
      Person(
        id: HouseSync.newId('p'),
        name: next,
        roomId: store.house.rooms.first.id,
      ),
    );
  }

  Future<String?> _prompt(
    BuildContext context, {
    required String title,
    required String initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(border: OutlineInputBorder()),
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
  }
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
        backgroundColor: roomFill(
          person.roomId,
          Theme.of(context).brightness,
          store.house,
        ),
        child: Text(
          person.name.isEmpty ? '?' : person.name.characters.first,
          style: TextStyle(
            color: roomColor(person.roomId, store.house),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(person.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value:
                store.house.roomById(person.roomId)?.id ??
                store.house.rooms.first.id,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            items: [
              for (final room in store.house.rooms)
                DropdownMenuItem(value: room.id, child: Text(room.name)),
            ],
            onChanged: (room) {
              if (room == null) return;
              store.savePerson(person.copyWith(roomId: room));
            },
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close, size: 18),
            onPressed: store.people.length <= 1
                ? null
                : () => store.removePerson(person.id),
          ),
        ],
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
                  ? 'Tap Allow, then Allow on the iPhone prompt. If you said Don’t Allow, turn them on in Settings → notifications for this app.'
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
                          'Still off — enable notifications for this app in Settings',
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
                            'Turn on notifications for this app in system settings first',
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

class _JobRuleTile extends StatelessWidget {
  const _JobRuleTile({required this.store, required this.type});

  final HouseStore store;
  final JobType type;

  static const _days = [
    (DateTime.monday, 'Mon'),
    (DateTime.tuesday, 'Tue'),
    (DateTime.wednesday, 'Wed'),
    (DateTime.thursday, 'Thu'),
    (DateTime.friday, 'Fri'),
    (DateTime.saturday, 'Sat'),
    (DateTime.sunday, 'Sun'),
  ];

  @override
  Widget build(BuildContext context) {
    final rule = store.house.rule(type);
    final days = rule.weekdays
        .map(
          (w) => _days.firstWhere((d) => d.$1 == w, orElse: () => (w, '$w')).$2,
        )
        .join(', ');
    return Card(
      child: ListTile(
        title: Text(
          rule.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          rule.sundayFollowsUpstairs
              ? '$days · Sun follows upstairs'
              : '$days · ${rule.cycle.map((r) => 'R$r').join('→')}',
        ),
        trailing: const Icon(Icons.tune),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _JobRuleSheet(store: store, type: type),
          );
        },
      ),
    );
  }
}

class _JobRuleSheet extends StatefulWidget {
  const _JobRuleSheet({required this.store, required this.type});

  final HouseStore store;
  final JobType type;

  @override
  State<_JobRuleSheet> createState() => _JobRuleSheetState();
}

class _JobRuleSheetState extends State<_JobRuleSheet> {
  static const _days = _JobRuleTile._days;

  late JobRule _rule;
  late final TextEditingController _title;
  late final TextEditingController _blurb;

  @override
  void initState() {
    super.initState();
    _rule = widget.store.house.rule(widget.type);
    _title = TextEditingController(text: _rule.title);
    _blurb = TextEditingController(text: _rule.blurb);
  }

  @override
  void dispose() {
    _title.dispose();
    _blurb.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _rule.weekdays.isEmpty || _rule.cycle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need a name, at least one day, and one room'),
        ),
      );
      return;
    }
    final rules = Map<JobType, JobRule>.from(widget.store.house.rules);
    rules[widget.type] = _rule.copyWith(
      title: title,
      blurb: _blurb.text.trim().isEmpty ? _rule.blurb : _blurb.text.trim(),
    );
    await widget.store.saveHouse(widget.store.house.copyWith(rules: rules));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Job name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _blurb,
              decoration: const InputDecoration(labelText: 'Short description'),
            ),
            const SizedBox(height: 12),
            Text(
              'Days',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final day in _days)
                  FilterChip(
                    label: Text(day.$2),
                    selected: _rule.weekdays.contains(day.$1),
                    onSelected: (on) {
                      final w = [..._rule.weekdays];
                      if (on) {
                        w.add(day.$1);
                      } else {
                        w.remove(day.$1);
                      }
                      w.sort();
                      setState(() => _rule = _rule.copyWith(weekdays: w));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Room order',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final room in widget.store.house.rooms)
                  FilterChip(
                    label: Text(room.name),
                    selected: _rule.cycle.contains(room.id),
                    onSelected: (on) {
                      final c = [..._rule.cycle];
                      if (on) {
                        if (!c.contains(room.id)) c.add(room.id);
                      } else {
                        c.remove(room.id);
                      }
                      setState(() => _rule = _rule.copyWith(cycle: c));
                    },
                  ),
              ],
            ),
            TextButton(
              onPressed: _rule.cycle.length < 2
                  ? null
                  : () {
                      final c = [..._rule.cycle];
                      c.add(c.removeAt(0));
                      setState(() => _rule = _rule.copyWith(cycle: c));
                    },
              child: Text(
                'Rotate order: ${_rule.cycle.map((r) => 'R$r').join(' → ')}',
              ),
            ),
            if (_rule.weekdayRooms.isEmpty)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fixed room on each weekday'),
                subtitle: const Text(
                  'Pin Mon, Tue, … to a room instead of rotating',
                ),
                value: false,
                onChanged: (on) {
                  if (!on) return;
                  setState(
                    () => _rule = _rule.copyWith(
                      weekdayRooms: HouseProfile.pairedWeekdayRooms(
                        widget.store.house.rooms.map((r) => r.id).toList(),
                      ),
                    ),
                  );
                },
              )
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fixed room on each weekday'),
                subtitle: const Text(
                  'Turn off to use the room order above instead of pinned days',
                ),
                value: true,
                onChanged: (_) => setState(
                  () => _rule = _rule.copyWith(weekdayRooms: const {}),
                ),
              ),
              for (final day in _days)
                if (day.$1 != DateTime.sunday || !_rule.sundayFollowsUpstairs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 44, child: Text(day.$2)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value:
                                widget.store.house.roomById(
                                      _rule.weekdayRooms[day.$1] ??
                                          _rule.cycle.first,
                                    ) !=
                                    null
                                ? (_rule.weekdayRooms[day.$1] ??
                                      _rule.cycle.first)
                                : widget.store.house.rooms.first.id,
                            items: [
                              for (final room in widget.store.house.rooms)
                                DropdownMenuItem(
                                  value: room.id,
                                  child: Text(room.name),
                                ),
                            ],
                            onChanged: (id) {
                              if (id == null) return;
                              final next = Map<int, int>.from(
                                _rule.weekdayRooms,
                              );
                              next[day.$1] = id;
                              setState(
                                () =>
                                    _rule = _rule.copyWith(weekdayRooms: next),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
            if (widget.type == JobType.garbage)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sunday follows upstairs'),
                value: _rule.sundayFollowsUpstairs,
                onChanged: (v) => setState(
                  () => _rule = _rule.copyWith(sundayFollowsUpstairs: v),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(
                _rule.epoch == null
                    ? 'Not set'
                    : '${_rule.epoch!.day}/${_rule.epoch!.month}/${_rule.epoch!.year}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _rule.epoch ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2032),
                );
                if (picked == null) return;
                setState(
                  () => _rule = _rule.copyWith(
                    epoch: DateTime(picked.year, picked.month, picked.day),
                  ),
                );
              },
            ),
            FilledButton(onPressed: _save, child: const Text('Save rule')),
          ],
        ),
      ),
    );
  }
}
