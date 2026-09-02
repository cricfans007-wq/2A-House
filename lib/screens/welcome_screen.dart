import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/house_store.dart';
import '../data/house_sync.dart';
import '../models.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.store, required this.sync});

  final HouseStore store;
  final HouseSync sync;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  var _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() work) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
          children: [
            Text(
              'House chores',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a house for your roommates, or join one with an invite code. Everyone shares the same board.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (store.hasLegacyRoster) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This phone already has a roster',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store.people.map((p) => p.name).join(', '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                await widget.sync.createHouse(
                                  name: store.house.name.isEmpty
                                      ? '2A House'
                                      : store.house.name,
                                  rooms: store.house.rooms,
                                  people: store.people,
                                  rules: store.house.rules,
                                );
                              }),
                        child: const Text('Keep this house and get a code'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _CreateHousePage(store: store, sync: widget.sync),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Create a house'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _JoinHousePage(sync: widget.sync),
                        ),
                      );
                    },
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Join with a code'),
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JoinHousePage extends StatefulWidget {
  const _JoinHousePage({required this.sync});

  final HouseSync sync;

  @override
  State<_JoinHousePage> createState() => _JoinHousePageState();
}

class _JoinHousePageState extends State<_JoinHousePage> {
  final _code = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.sync.joinHouse(_code.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a house')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: '8 letters and numbers',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _join,
            child: const Text('Join'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateHousePage extends StatefulWidget {
  const _CreateHousePage({required this.store, required this.sync});

  final HouseStore store;
  final HouseSync sync;

  @override
  State<_CreateHousePage> createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<_CreateHousePage> {
  final _name = TextEditingController(text: 'Our house');
  final _roomNames = [
    TextEditingController(text: 'Room 1'),
    TextEditingController(text: 'Room 2'),
  ];
  final _people = <(TextEditingController, int)>[(TextEditingController(), 1)];
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _roomNames) {
      c.dispose();
    }
    for (final p in _people) {
      p.$1.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    final rooms = <HouseRoom>[];
    for (var i = 0; i < _roomNames.length; i++) {
      final label = _roomNames[i].text.trim();
      rooms.add(
        HouseRoom(
          id: i + 1,
          name: label.isEmpty ? 'Room ${i + 1}' : label,
          colorValue: roomPalette[i % roomPalette.length],
        ),
      );
    }
    final people = <Person>[];
    for (var i = 0; i < _people.length; i++) {
      final n = _people[i].$1.text.trim();
      if (n.isEmpty) continue;
      people.add(
        Person(id: HouseSync.newId('p'), name: n, roomId: _people[i].$2),
      );
    }
    if (people.isEmpty) {
      setState(() => _error = 'Add at least one person');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.sync.createHouse(
        name: _name.text,
        rooms: rooms,
        people: people,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a house')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'House name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Rooms',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _roomNames.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _roomNames[i],
                decoration: InputDecoration(
                  labelText: 'Room ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          if (_roomNames.length < 8)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _roomNames.add(
                    TextEditingController(
                      text: 'Room ${_roomNames.length + 1}',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add a room'),
            ),
          const SizedBox(height: 12),
          Text(
            'People',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _people.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _people[i].$1,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _people[i].$2 <= _roomNames.length
                        ? _people[i].$2
                        : 1,
                    items: [
                      for (var r = 1; r <= _roomNames.length; r++)
                        DropdownMenuItem(value: r, child: Text('R$r')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _people[i] = (_people[i].$1, v));
                    },
                  ),
                ],
              ),
            ),
          if (_people.length < 24)
            TextButton.icon(
              onPressed: () {
                setState(() => _people.add((TextEditingController(), 1)));
              },
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add a person'),
            ),
          const SizedBox(height: 8),
          Text(
            'Chore days start as downstairs Wed/Sun, upstairs Sundays, garbage all week with Sunday following upstairs. You can change that in House after you create.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Create house'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
