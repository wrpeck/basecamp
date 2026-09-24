import 'dart:math';

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 20)}';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

class CostItem {
  CostItem({
    String? id,
    required this.label,
    required this.amount,
    this.paidBy = '',
  }) : id = id ?? newId();

  final String id;
  String label;
  double amount;
  String paidBy;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'paidBy': paidBy,
  };

  factory CostItem.fromJson(Map<String, dynamic> j) => CostItem(
    id: j['id'],
    label: j['label'] ?? '',
    amount: _d(j['amount']),
    paidBy: j['paidBy'] ?? '',
  );
}

class Camper {
  Camper({
    String? id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.role = '',
    this.emergencyContact = '',
    this.notes = '',
  }) : id = id ?? newId();

  final String id;
  String name;
  String phone;
  String email;
  String role;
  String emergencyContact;
  String notes;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'role': role,
    'emergencyContact': emergencyContact,
    'notes': notes,
  };

  factory Camper.fromJson(Map<String, dynamic> j) => Camper(
    id: j['id'],
    name: j['name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? '',
    emergencyContact: j['emergencyContact'] ?? '',
    notes: j['notes'] ?? '',
  );
}

const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

class Meal {
  Meal({
    String? id,
    required this.day,
    required this.type,
    required this.title,
    this.ingredients = const [],
    this.cook = '',
    this.notes = '',
  }) : id = id ?? newId();

  final String id;
  int day;
  String type;
  String title;
  List<String> ingredients;
  String cook;
  String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'type': type,
    'title': title,
    'ingredients': ingredients,
    'cook': cook,
    'notes': notes,
  };

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'],
    day: j['day'] ?? 0,
    type: j['type'] ?? 'Dinner',
    title: j['title'] ?? '',
    ingredients: List<String>.from(j['ingredients'] ?? const []),
    cook: j['cook'] ?? '',
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
    this.bringer = '',
  }) : id = id ?? newId();

  final String id;
  String name;
  String category;
  int quantity;
  bool packed;
  String bringer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'packed': packed,
    'bringer': bringer,
  };

  factory GearItem.fromJson(Map<String, dynamic> j) => GearItem(
    id: j['id'],
    name: j['name'] ?? '',
    category: j['category'] ?? 'Other',
    quantity: j['quantity'] ?? 1,
    packed: j['packed'] ?? false,
    bringer: j['bringer'] ?? '',
  );
}

const activityKinds = [
  'Hike',
  'Day trip',
  'Water',
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
    this.time = '',
    this.location = '',
    this.distance = '',
    this.notes = '',
    this.done = false,
  }) : id = id ?? newId();

  final String id;
  int day;
  String title;
  String kind;
  String time;
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
    kind: j['kind'] ?? 'Other',
    time: j['time'] ?? '',
    location: j['location'] ?? '',
    distance: j['distance'] ?? '',
    notes: j['notes'] ?? '',
    done: j['done'] ?? false,
  );
}

class Trip {
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
    this.checkIn = '',
    this.checkOut = '',
    this.reservationNumber = '',
    this.parking = '',
    this.rangerPhone = '',
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
  String checkIn;
  String checkOut;
  String reservationNumber;
  String parking;
  String rangerPhone;
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
  double get costPerPerson =>
      campers.isEmpty ? totalCost : totalCost / campers.length;
  int get packedCount => gear.where((g) => g.packed).length;
  double get packedFraction => gear.isEmpty ? 0 : packedCount / gear.length;
  bool get hasCoordinates => latitude != null && longitude != null;

  int daysUntil(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return startDate.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {
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
    'parking': parking,
    'rangerPhone': rangerPhone,
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

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'],
    name: j['name'] ?? '',
    startDate: DateTime.parse(j['startDate']),
    endDate: DateTime.parse(j['endDate']),
    campground: j['campground'] ?? '',
    siteNumber: j['siteNumber'] ?? '',
    address: j['address'] ?? '',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    checkIn: j['checkIn'] ?? '',
    checkOut: j['checkOut'] ?? '',
    reservationNumber: j['reservationNumber'] ?? '',
    parking: j['parking'] ?? '',
    rangerPhone: j['rangerPhone'] ?? '',
    notes: j['notes'] ?? '',
    costs: _list(j['costs'], CostItem.fromJson),
    campers: _list(j['campers'], Camper.fromJson),
    meals: _list(j['meals'], Meal.fromJson),
    gear: _list(j['gear'], GearItem.fromJson),
    activities: _list(j['activities'], Activity.fromJson),
  );
}
