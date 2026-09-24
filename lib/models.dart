import 'dart:math';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 20)}';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
List<String> _strings(Object? v) => List<String>.from((v as List?) ?? const []);

/// Parses legacy free-text times like "2:00 PM" into minutes after midnight.
int? parseTime(Object? raw) {
  if (raw is int) return raw;
  if (raw is! String || raw.trim().isEmpty) return null;
  final m = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*([ap])?',
    caseSensitive: false,
  ).firstMatch(raw);
  if (m == null) return null;
  var h = int.parse(m[1]!);
  final min = int.tryParse(m[2] ?? '') ?? 0;
  final ap = m[3]?.toLowerCase();
  if (ap != null) h = h % 12 + (ap == 'p' ? 12 : 0);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

class CostItem {
  CostItem({
    String? id,
    required this.label,
    required this.amount,
    List<String>? payerIds,
    List<String>? owedIds,
    this.owedByEveryone = false,
  }) : id = id ?? newId(),
       payerIds = payerIds ?? [],
       owedIds = owedIds ?? [];

  final String id;
  String label;
  double amount;

  /// Campers who paid. The amount is split evenly between them.
  List<String> payerIds;

  /// Campers who share the cost. Ignored when [owedByEveryone] is set.
  List<String> owedIds;
  bool owedByEveryone;

  /// Nobody else owes anything for it, e.g. "my snacks".
  bool get isPersonal => !owedByEveryone && owedIds.isEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'payerIds': payerIds,
    'owedIds': owedIds,
    'owedByEveryone': owedByEveryone,
  };

  factory CostItem.fromJson(Map<String, dynamic> j) => CostItem(
    id: j['id'],
    label: j['label'] ?? '',
    amount: _d(j['amount']),
    payerIds: _strings(j['payerIds']),
    owedIds: _strings(j['owedIds']),
    // Costs from before "owed" existed were split with everyone.
    owedByEveryone: j['owedByEveryone'] ?? !j.containsKey('owedIds'),
  );
}

class Camper {
  Camper({
    String? id,
    required this.name,
    this.isMe = false,
    this.phone = '',
    this.email = '',
    this.role = '',
    this.emergencyContact = '',
    this.notes = '',
  }) : id = id ?? newId();

  final String id;
  String name;
  bool isMe;
  String phone;
  String email;
  String role;
  String emergencyContact;
  String notes;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isMe': isMe,
    'phone': phone,
    'email': email,
    'role': role,
    'emergencyContact': emergencyContact,
    'notes': notes,
  };

  factory Camper.fromJson(Map<String, dynamic> j) => Camper(
    id: j['id'],
    name: j['name'] ?? '',
    isMe: j['isMe'] ?? false,
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? '',
    emergencyContact: j['emergencyContact'] ?? '',
    notes: j['notes'] ?? '',
  );
}

const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

/// How a meal slot is covered.
const provisionGroup = 'Group meal';
const provisionSelf = 'Self-provided';
const provisionNone = 'N/A';
const mealProvisions = [provisionGroup, provisionSelf, provisionNone];

class Meal {
  Meal({
    String? id,
    required this.day,
    required this.type,
    this.title = '',
    this.provision = provisionGroup,
    List<String>? ingredients,
    List<String>? cookIds,
    this.notes = '',
  }) : id = id ?? newId(),
       ingredients = ingredients ?? [],
       cookIds = cookIds ?? [];

  final String id;
  int day;
  String type;
  String title;
  String provision;
  List<String> ingredients;
  List<String> cookIds;
  String notes;

  bool get isGroup => provision == provisionGroup;

  String get displayTitle {
    if (title.isNotEmpty) return title;
    return switch (provision) {
      provisionSelf => 'Bring your own',
      provisionNone => 'No meal planned',
      _ => type,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'type': type,
    'title': title,
    'provision': provision,
    'ingredients': ingredients,
    'cookIds': cookIds,
    'notes': notes,
  };

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'],
    day: j['day'] ?? 0,
    type: j['type'] ?? 'Dinner',
    title: j['title'] ?? '',
    provision: mealProvisions.contains(j['provision'])
        ? j['provision']
        : provisionGroup,
    ingredients: _strings(j['ingredients']),
    cookIds: _strings(j['cookIds']),
    notes: j['notes'] ?? '',
  );
}

const gearCategories = [
  'Shelter',
  'Sleep',
  'Kitchen',
  'Clothing',
  'Safety',
  'Tools',
  'Personal',
  'Fun',
  'Other',
];

class GearItem {
  GearItem({
    String? id,
    required this.name,
    this.category = 'Other',
    this.quantity = 1,
    this.packed = false,
    this.bringerId = '',
    List<String>? forIds,
  }) : id = id ?? newId(),
       forIds = forIds ?? [];

  final String id;
  String name;
  String category;
  int quantity;
  bool packed;
  String bringerId;

  /// Who the item is for. Empty means anyone can use it.
  List<String> forIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'packed': packed,
    'bringerId': bringerId,
    'forIds': forIds,
  };

  factory GearItem.fromJson(Map<String, dynamic> j) => GearItem(
    id: j['id'],
    name: j['name'] ?? '',
    category: j['category'] ?? 'Other',
    quantity: j['quantity'] ?? 1,
    packed: j['packed'] ?? false,
    bringerId: j['bringerId'] ?? '',
    forIds: _strings(j['forIds']),
  );
}

const activityKinds = [
  'Hike',
  'Day trip',
  'Water Sports',
  'Biking',
  'Climbing',
  'Stargazing',
  'Camp',
  'Sightseeing',
  'Other',
];

class Activity {
  Activity({
    String? id,
    required this.day,
    required this.title,
    this.kind = 'Hike',
    this.time,
    this.location = '',
    this.distance = '',
    this.notes = '',
    this.done = false,
  }) : id = id ?? newId();

  final String id;
  int day;
  String title;
  String kind;

  /// Minutes after midnight, or null when unscheduled.
  int? time;
  String location;
  String distance;
  String notes;
  bool done;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'title': title,
    'kind': kind,
    'time': time,
    'location': location,
    'distance': distance,
    'notes': notes,
    'done': done,
  };

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'],
    day: j['day'] ?? 0,
    title: j['title'] ?? '',
    kind: j['kind'] == 'Water' ? 'Water Sports' : (j['kind'] ?? 'Other'),
    time: parseTime(j['time']),
    location: j['location'] ?? '',
    distance: j['distance'] ?? '',
    notes: j['notes'] ?? '',
    done: j['done'] ?? false,
  );
}

const waterOptions = [
  'Unknown',
  'Potable water at site',
  'Spigot nearby',
  'Non-potable only',
  'None – bring your own',
];

const bathroomOptions = [
  'Unknown',
  'Flush toilets & showers',
  'Flush toilets',
  'Vault / pit toilets',
  'Portable toilets',
  'None',
];

/// Net amount [from] owes [to].
class Debt {
  const Debt(this.from, this.to, this.amount);
  final String from;
  final String to;
  final double amount;
}

class Trip {
  static const schemaVersion = 2;

  Trip({
    String? id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.campground = '',
    this.siteNumber = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.checkIn,
    this.checkOut,
    this.reservationNumber = '',
    this.water = 'Unknown',
    this.bathrooms = 'Unknown',
    this.cellService = false,
    this.vehiclesAllowed,
    this.costPerVehicle,
    this.parkingNotes = '',
    this.leaveHomeBy,
    this.arriveCampBy,
    this.leaveCampBy,
    this.arriveHomeBy,
    this.notes = '',
    List<CostItem>? costs,
    List<Camper>? campers,
    List<Meal>? meals,
    List<GearItem>? gear,
    List<Activity>? activities,
  }) : id = id ?? newId(),
       costs = costs ?? [],
       campers = campers ?? [],
       meals = meals ?? [],
       gear = gear ?? [],
       activities = activities ?? [];

  final String id;
  String name;
  DateTime startDate;
  DateTime endDate;
  String campground;
  String siteNumber;
  String address;
  double? latitude;
  double? longitude;
  int? checkIn;
  int? checkOut;
  String reservationNumber;
  String water;
  String bathrooms;
  bool cellService;
  int? vehiclesAllowed;
  double? costPerVehicle;
  String parkingNotes;
  int? leaveHomeBy;
  int? arriveCampBy;
  int? leaveCampBy;
  int? arriveHomeBy;
  String notes;
  List<CostItem> costs;
  List<Camper> campers;
  List<Meal> meals;
  List<GearItem> gear;
  List<Activity> activities;

  int get dayCount => endDate.difference(startDate).inDays + 1;
  int get nights => max(0, dayCount - 1);
  DateTime dateForDay(int day) => startDate.add(Duration(days: day));
  double get totalCost => costs.fold(0, (s, c) => s + c.amount);
  int get packedCount => gear.where((g) => g.packed).length;
  double get packedFraction => gear.isEmpty ? 0 : packedCount / gear.length;
  bool get hasCoordinates => latitude != null && longitude != null;

  Camper? get me {
    for (final c in campers) {
      if (c.isMe) return c;
    }
    return null;
  }

  Camper? camper(String id) {
    for (final c in campers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Display names for [ids], skipping campers that no longer exist.
  List<String> names(Iterable<String> ids) =>
      ids.map(camper).whereType<Camper>().map((c) => c.firstName).toList();

  int daysUntil(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return startDate.difference(today).inDays;
  }

  List<String> _payers(CostItem c) =>
      c.payerIds.where((id) => camper(id) != null).toList();

  List<String> _sharers(CostItem c) => c.owedByEveryone
      ? campers.map((c) => c.id).toList()
      : c.owedIds.where((id) => camper(id) != null).toList();

  /// What this camper's trip costs them: their share of shared costs plus
  /// personal expenses they paid for.
  double costFor(String camperId) {
    var total = 0.0;
    for (final c in costs) {
      if (c.isPersonal) {
        final payers = _payers(c);
        if (payers.contains(camperId)) total += c.amount / payers.length;
      } else {
        final sharers = _sharers(c);
        if (sharers.contains(camperId)) total += c.amount / sharers.length;
      }
    }
    return total;
  }

  double paidBy(String camperId) {
    var total = 0.0;
    for (final c in costs) {
      final payers = _payers(c);
      if (payers.contains(camperId)) total += c.amount / payers.length;
    }
    return total;
  }

  /// Net balances between campers, simplified so each pair appears once.
  List<Debt> debts() {
    final owes = <String, Map<String, double>>{};
    for (final c in costs) {
      if (c.isPersonal) continue;
      final payers = _payers(c);
      final sharers = _sharers(c);
      if (payers.isEmpty || sharers.isEmpty) continue;
      final each = c.amount / sharers.length / payers.length;
      for (final d in sharers) {
        for (final p in payers) {
          if (d == p) continue;
          owes.putIfAbsent(d, () => {})[p] = (owes[d]?[p] ?? 0) + each;
        }
      }
    }
    final result = <Debt>[];
    final seen = <String>{};
    for (final a in owes.keys) {
      for (final b in owes[a]!.keys) {
        final key = ([a, b]..sort()).join('|');
        if (!seen.add(key)) continue;
        final net = owes[a]![b]! - (owes[b]?[a] ?? 0);
        if (net > 0.005) result.add(Debt(a, b, net));
        if (net < -0.005) result.add(Debt(b, a, -net));
      }
    }
    return result;
  }

  /// Removes references to a camper who is being deleted.
  void forgetCamper(String id) {
    for (final c in costs) {
      c.payerIds.remove(id);
      c.owedIds.remove(id);
    }
    for (final m in meals) {
      m.cookIds.remove(id);
    }
    for (final g in gear) {
      if (g.bringerId == id) g.bringerId = '';
      g.forIds.remove(id);
    }
    campers.removeWhere((c) => c.id == id);
  }

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'campground': campground,
    'siteNumber': siteNumber,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'reservationNumber': reservationNumber,
    'water': water,
    'bathrooms': bathrooms,
    'cellService': cellService,
    'vehiclesAllowed': vehiclesAllowed,
    'costPerVehicle': costPerVehicle,
    'parkingNotes': parkingNotes,
    'leaveHomeBy': leaveHomeBy,
    'arriveCampBy': arriveCampBy,
    'leaveCampBy': leaveCampBy,
    'arriveHomeBy': arriveHomeBy,
    'notes': notes,
    'costs': costs.map((e) => e.toJson()).toList(),
    'campers': campers.map((e) => e.toJson()).toList(),
    'meals': meals.map((e) => e.toJson()).toList(),
    'gear': gear.map((e) => e.toJson()).toList(),
    'activities': activities.map((e) => e.toJson()).toList(),
  };

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
      ((raw as List?) ?? const [])
          .map((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();

  factory Trip.fromJson(Map<String, dynamic> j) {
    final trip = Trip(
      id: j['id'],
      name: j['name'] ?? '',
      startDate: DateTime.parse(j['startDate']),
      endDate: DateTime.parse(j['endDate']),
      campground: j['campground'] ?? '',
      siteNumber: j['siteNumber'] ?? '',
      address: j['address'] ?? '',
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      checkIn: parseTime(j['checkIn']),
      checkOut: parseTime(j['checkOut']),
      reservationNumber: j['reservationNumber'] ?? '',
      water: waterOptions.contains(j['water']) ? j['water'] : 'Unknown',
      bathrooms: bathroomOptions.contains(j['bathrooms'])
          ? j['bathrooms']
          : 'Unknown',
      cellService: j['cellService'] ?? false,
      vehiclesAllowed: j['vehiclesAllowed'],
      costPerVehicle: (j['costPerVehicle'] as num?)?.toDouble(),
      parkingNotes: j['parkingNotes'] ?? j['parking'] ?? '',
      leaveHomeBy: j['leaveHomeBy'],
      arriveCampBy: j['arriveCampBy'],
      leaveCampBy: j['leaveCampBy'],
      arriveHomeBy: j['arriveHomeBy'],
      notes: j['notes'] ?? '',
      costs: _list(j['costs'], CostItem.fromJson),
      campers: _list(j['campers'], Camper.fromJson),
      meals: _list(j['meals'], Meal.fromJson),
      gear: _list(j['gear'], GearItem.fromJson),
      activities: _list(j['activities'], Activity.fromJson),
    );
    if ((j['v'] ?? 1) < 2) trip._migrateFromV1(j);
    return trip;
  }

  /// Version 1 referred to campers by first name and had no "Me".
  void _migrateFromV1(Map<String, dynamic> j) {
    String idFor(Object? name) {
      if (name is! String || name.isEmpty) return '';
      for (final c in campers) {
        if (c.firstName == name) return c.id;
      }
      return '';
    }

    final rawCosts = (j['costs'] as List?) ?? const [];
    for (var i = 0; i < costs.length && i < rawCosts.length; i++) {
      final id = idFor((rawCosts[i] as Map)['paidBy']);
      if (id.isNotEmpty) costs[i].payerIds = [id];
    }
    final rawMeals = (j['meals'] as List?) ?? const [];
    for (var i = 0; i < meals.length && i < rawMeals.length; i++) {
      final id = idFor((rawMeals[i] as Map)['cook']);
      if (id.isNotEmpty) meals[i].cookIds = [id];
    }
    final rawGear = (j['gear'] as List?) ?? const [];
    for (var i = 0; i < gear.length && i < rawGear.length; i++) {
      gear[i].bringerId = idFor((rawGear[i] as Map)['bringer']);
    }
    if (me == null) campers.insert(0, Camper(name: 'Me', isMe: true));
  }
}
