import 'package:flutter/material.dart';

import '../util.dart';
import '../widgets/form_sheet.dart';
import 'crew_tab.dart';
import 'gear_tab.dart';
import 'meals_tab.dart';
import 'overview_tab.dart';
import 'plans_tab.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  int _tab = 0;

  static const _titles = ['Overview', 'Meals', 'Gear', 'Plans', 'Crew'];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final trip = store.byId(widget.tripId);
    if (trip == null) return const Scaffold();

    final tabs = [
      OverviewTab(trip: trip),
      MealsTab(trip: trip),
      GearTab(trip: trip),
      PlansTab(trip: trip),
      CrewTab(trip: trip),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? trip.name : _titles[_tab]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final values = await showFormSheet(
                  context,
                  title: 'Rename trip',
                  fields: [
                    FieldSpec.text(
                      'name',
                      'Trip name',
                      initial: trip.name,
                      required: true,
                    ),
                  ],
                );
                if (values != null) {
                  store.update(() => trip.name = values.str('name'));
                }
              } else if (v == 'delete') {
                final ok = await confirm(
                  context,
                  'Delete trip?',
                  '"${trip.name}" and everything in it will be removed.',
                );
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                  store.removeTrip(trip);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename trip')),
              PopupMenuItem(value: 'delete', child: Text('Delete trip')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Meals',
          ),
          NavigationDestination(
            icon: Icon(Icons.backpack_outlined),
            selectedIcon: Icon(Icons.backpack),
            label: 'Gear',
          ),
          NavigationDestination(
            icon: Icon(Icons.hiking_outlined),
            selectedIcon: Icon(Icons.hiking),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Crew',
          ),
        ],
      ),
    );
  }
}
