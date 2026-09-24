import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'sample_data.dart';

/// Holds every trip and the user's reusable gear lists, persisted locally as
/// JSON. This is the seam a synced backend would replace.
class TripStore extends ChangeNotifier {
  static const _tripsKey = 'basecamp.trips.v1';
  static const _templatesKey = 'basecamp.gearLists.v1';

  final List<Trip> trips = [];
  final List<GearTemplate> templates = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_tripsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        trips.addAll(
          list.map((e) => Trip.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      final rawTemplates = _prefs!.getString(_templatesKey);
      if (rawTemplates != null) {
        final list = jsonDecode(rawTemplates) as List;
        templates.addAll(
          list.map((e) => GearTemplate.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      if (rawTemplates == null) templates.addAll(defaultGearTemplates());
    } catch (e) {
      debugPrint('Could not load data: $e');
    }
    if (trips.isEmpty) trips.add(sampleTrip());
    _persist();
    notifyListeners();
  }

  Trip? byId(String id) {
    for (final t in trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Apply [change] to state, then save and rebuild listeners.
  void update(VoidCallback change) {
    change();
    _persist();
    notifyListeners();
  }

  void addTrip(Trip trip) => update(() => trips.add(trip));
  void removeTrip(Trip trip) => update(() => trips.remove(trip));

  /// Deletes everything and starts over with the sample trip and default
  /// gear lists.
  void resetAll() => update(() {
    trips
      ..clear()
      ..add(sampleTrip());
    templates
      ..clear()
      ..addAll(defaultGearTemplates());
  });

  void _persist() {
    try {
      _prefs?.setString(
        _tripsKey,
        jsonEncode(trips.map((t) => t.toJson()).toList()),
      );
      _prefs?.setString(
        _templatesKey,
        jsonEncode(templates.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Could not save data: $e');
    }
  }
}
