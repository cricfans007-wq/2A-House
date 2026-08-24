import 'package:flutter/material.dart';

import '../data/house_store.dart';
import '../data/notifications.dart';
import '../theme.dart';
import 'calendar_tab.dart';
import 'person_tab.dart';
import 'settings_tab.dart';
import 'week_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final HouseStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  var _askedWho = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      WeekTab(store: widget.store),
      PersonTab(store: widget.store),
      CalendarTab(store: widget.store),
      SettingsTab(store: widget.store),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  Future<void> _afterFirstFrame() async {
    await _maybeAskWho();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final ok = await NotificationService.instance.requestPermission();
    if (ok) {
      await NotificationService.instance.resync(widget.store);
    }
  }

  Future<void> _maybeAskWho() async {
    if (_askedWho || widget.store.settings.myPersonId != null) return;
    if (!mounted) return;
    _askedWho = true;
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who are you?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Used for reminders and to highlight your room’s jobs. Everyone still sees the full board.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final p in widget.store.people)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: roomFill(
                        p.roomId,
                        Theme.of(context).brightness,
                      ),
                      child: Text(
                        p.name.characters.first,
                        style: TextStyle(
                          color: roomColor(p.roomId),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text('Room ${p.roomId}'),
                    onTap: () => Navigator.pop(context, p.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (id == null) return;
    await widget.store.saveSettings(
      widget.store.settings.copyWith(myPersonId: id),
    );
    await NotificationService.instance.resync(widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.me;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2A House'),
                if (me != null)
                  Text(
                    '${me.name} · Room ${me.roomId}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible:
                      store.me != null && store.hasUpcomingBadge(store.me!),
                  child: const Icon(Icons.people_outline),
                ),
                selectedIcon: const Icon(Icons.people),
                label: 'People',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.cottage_outlined),
                selectedIcon: Icon(Icons.cottage),
                label: 'House',
              ),
            ],
          ),
        );
      },
    );
  }
}
