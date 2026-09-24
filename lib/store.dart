import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'sample_data.dart';

/// Holds every trip and persists them locally as JSON.
class TripStore extends ChangeNotifier {
  static const _key = 'basecamp.trips.v1';

  final List<Trip> trips = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        trips.addAll(
          list.map((e) => Trip.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } catch (e) {
      debugPrint('Could not load trips: $e');
    }
    if (trips.isEmpty) {
      trips.add(sampleTrip());
      _persist();
    }
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

  void _persist() {
    try {
      _prefs?.setString(
        _key,
        jsonEncode(trips.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Could not save trips: $e');
    }
  }
}
