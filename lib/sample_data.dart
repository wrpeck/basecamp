import 'models.dart';

/// Every new trip starts with "Me" on the crew.
Trip newTrip({
  required String name,
  required String campground,
  required DateTime start,
  required DateTime end,
}) => Trip(
  name: name,
  campground: campground,
  startDate: start,
  endDate: end,
  campers: [Camper(name: 'Me', isMe: true)],
);

/// A fully filled-in example trip so the app has something to show on first
/// launch. Dates float relative to today so the countdown stays meaningful.
Trip sampleTrip() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day + 21);
  final end = start.add(const Duration(days: 2));

  final me = Camper(name: 'Me', isMe: true, role: 'Trip lead · Driver');
  final jordan = Camper(
    name: 'Jordan Lee',
    phone: '(555) 318-2210',
    email: 'jordan@example.com',
    role: 'Camp chef',
    emergencyContact: 'Chris Lee (555) 318-7788',
    notes: 'Vegetarian',
  );
  final sam = Camper(
    name: 'Sam Patel',
    phone: '(555) 442-0917',
    email: 'sam@example.com',
    role: 'Fire & water',
  );
  final riley = Camper(
    name: 'Riley Chen',
    phone: '(555) 660-3381',
    email: 'riley@example.com',
    role: 'Navigator · Driver',
    notes: 'Allergic to peanuts',
  );

  int t(int h, [int m = 0]) => h * 60 + m;

  return Trip(
    name: 'Big Sur Weekend',
    startDate: start,
    endDate: end,
    campground: 'Pfeiffer Big Sur State Park',
    siteNumber: 'Site 142 (Redwood Loop)',
    address: '47225 CA-1, Big Sur, CA 93920',
    latitude: 36.2508,
    longitude: -121.7847,
    checkIn: t(14),
    checkOut: t(12),
    reservationNumber: 'RC-48213-77',
    water: 'Potable water at site',
    bathrooms: 'Flush toilets & showers',
    cellService: false,
    vehiclesAllowed: 2,
    costPerVehicle: 10,
    parkingNotes:
        'Extra cars park in the day-use lot by the lodge. Pay at the kiosk.',
    leaveHomeBy: t(9),
    arriveCampBy: t(14),
    leaveCampBy: t(11, 30),
    arriveHomeBy: t(16),
    notes:
        'Quiet hours 10 PM – 6 AM. Fires only in the site ring. '
        'Download offline maps before Carmel!',
    campers: [me, jordan, sam, riley],
    costs: [
      CostItem(
        label: 'Campsite (2 nights)',
        amount: 140,
        payerIds: [me.id],
        owedByEveryone: true,
      ),
      CostItem(
        label: 'Groceries',
        amount: 186.40,
        payerIds: [jordan.id, sam.id],
        owedByEveryone: true,
      ),
      CostItem(
        label: 'Extra vehicle parking',
        amount: 20,
        payerIds: [riley.id],
        owedIds: [riley.id, sam.id],
      ),
      CostItem(label: 'My trail snacks', amount: 18.50, payerIds: [me.id]),
    ],
    meals: [
      Meal(
        day: 0,
        type: 'Lunch',
        provision: provisionSelf,
        notes: 'Eat on the drive down',
      ),
      Meal(
        day: 0,
        type: 'Dinner',
        title: 'Foil-packet fajitas',
        ingredients: ['Tortillas', 'Peppers', 'Onions', 'Chicken', 'Salsa'],
        cookIds: [jordan.id, riley.id],
      ),
      Meal(
        day: 0,
        type: 'Snack',
        title: 'S\'mores',
        ingredients: ['Graham crackers', 'Marshmallows', 'Chocolate'],
      ),
      Meal(
        day: 1,
        type: 'Breakfast',
        title: 'Skillet pancakes & bacon',
        ingredients: ['Pancake mix', 'Bacon', 'Maple syrup', 'Coffee'],
        cookIds: [me.id],
      ),
      Meal(
        day: 1,
        type: 'Lunch',
        title: 'Trail wraps',
        ingredients: ['Wraps', 'Hummus', 'Turkey', 'Spinach', 'Apples'],
      ),
      Meal(
        day: 1,
        type: 'Dinner',
        title: 'Campfire chili',
        ingredients: ['Beans', 'Ground beef', 'Tomatoes', 'Cornbread mix'],
        cookIds: [sam.id],
      ),
      Meal(
        day: 2,
        type: 'Breakfast',
        title: 'Breakfast burritos',
        ingredients: ['Eggs', 'Potatoes', 'Cheese', 'Tortillas'],
        cookIds: [riley.id],
      ),
      Meal(day: 2, type: 'Lunch', provision: provisionNone),
    ],
    gear: [
      GearItem(
        name: '4-person tent',
        category: 'Shelter',
        bringerId: me.id,
        packed: true,
      ),
      GearItem(
        name: 'Rain fly & stakes',
        category: 'Shelter',
        bringerId: me.id,
        packed: true,
      ),
      GearItem(name: 'Pop-up canopy', category: 'Shelter', bringerId: sam.id),
      GearItem(
        name: 'Camp chairs',
        category: 'Fun',
        quantity: 3,
        bringerId: me.id,
      ),
      GearItem(
        name: 'Camp chair',
        category: 'Fun',
        bringerId: me.id,
        forIds: [me.id],
      ),
      GearItem(
        name: 'Sleeping bags',
        category: 'Sleep',
        quantity: 4,
        packed: true,
      ),
      GearItem(name: 'Sleeping pads', category: 'Sleep', quantity: 4),
      GearItem(
        name: 'Camp stove + fuel',
        category: 'Kitchen',
        bringerId: jordan.id,
        packed: true,
      ),
      GearItem(
        name: 'Cast iron skillet',
        category: 'Kitchen',
        bringerId: jordan.id,
      ),
      GearItem(
        name: 'Cooler',
        category: 'Kitchen',
        quantity: 2,
        bringerId: sam.id,
      ),
      GearItem(name: 'Water jugs (5 gal)', category: 'Kitchen', quantity: 2),
      GearItem(name: 'Rain jackets', category: 'Clothing'),
      GearItem(name: 'Warm layers', category: 'Clothing'),
      GearItem(
        name: 'First aid kit',
        category: 'Safety',
        bringerId: riley.id,
        packed: true,
      ),
      GearItem(name: 'Headlamps', category: 'Safety', quantity: 4),
      GearItem(name: 'Bear-proof food bin', category: 'Safety'),
      GearItem(name: 'Hatchet', category: 'Tools', bringerId: sam.id),
      GearItem(name: 'Sunscreen & bug spray', category: 'Personal'),
      GearItem(
        name: 'Peanut-free snacks',
        category: 'Personal',
        bringerId: riley.id,
        forIds: [riley.id],
      ),
      GearItem(name: 'Card games', category: 'Fun', bringerId: riley.id),
    ],
    activities: [
      Activity(
        day: 0,
        title: 'Set up camp & gather firewood',
        kind: 'Camp',
        time: t(15),
      ),
      Activity(
        day: 0,
        title: 'Stargazing at the meadow',
        kind: 'Stargazing',
        time: t(21),
        notes: 'New moon weekend – bring a red light.',
      ),
      Activity(
        day: 1,
        title: 'Pfeiffer Falls & Valley View',
        kind: 'Hike',
        time: t(8, 30),
        location: 'Trailhead near the lodge',
        distance: '2.0 mi · 600 ft gain',
        notes: 'Bring water and snacks. Easy-moderate.',
      ),
      Activity(
        day: 1,
        title: 'McWay Falls overlook',
        kind: 'Day trip',
        time: t(13),
        location: 'Julia Pfeiffer Burns SP (15 min south)',
        distance: '0.6 mi round trip',
        notes: 'Day-use parking \$10. Great for photos.',
      ),
      Activity(
        day: 1,
        title: 'Sunset at Pfeiffer Beach',
        kind: 'Sightseeing',
        time: t(18, 15),
        location: 'Sycamore Canyon Rd',
        notes: 'Narrow road – no trailers. Look for the keyhole arch.',
      ),
      Activity(
        day: 2,
        title: 'Big Sur River swim',
        kind: 'Water Sports',
        time: t(9),
        location: 'River access by Loop B',
      ),
    ],
  );
}
