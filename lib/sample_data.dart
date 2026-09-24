import 'models.dart';

/// A fully filled-in example trip so the app has something to show on first
/// launch. Dates float relative to today so the countdown stays meaningful.
Trip sampleTrip() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day + 21);
  final end = start.add(const Duration(days: 2));

  return Trip(
    name: 'Big Sur Weekend',
    startDate: start,
    endDate: end,
    campground: 'Pfeiffer Big Sur State Park',
    siteNumber: 'Site 142 (Redwood Loop)',
    address: '47225 CA-1, Big Sur, CA 93920',
    latitude: 36.2508,
    longitude: -121.7847,
    checkIn: '2:00 PM',
    checkOut: '12:00 PM',
    reservationNumber: 'RC-48213-77',
    parking:
        '2 vehicles allowed at site. Extra cars park in the day-use lot by '
        'the lodge (\$10/day, pay at kiosk).',
    rangerPhone: '(831) 667-2315',
    notes:
        'Quiet hours 10 PM – 6 AM. Fires only in the site ring. '
        'No cell service past Carmel – download offline maps!',
    costs: [
      CostItem(label: 'Campsite (2 nights)', amount: 140, paidBy: 'Alex'),
      CostItem(label: 'Groceries', amount: 186.40, paidBy: 'Jordan'),
      CostItem(label: 'Firewood & ice', amount: 32, paidBy: 'Sam'),
      CostItem(label: 'Extra vehicle parking', amount: 20, paidBy: 'Riley'),
    ],
    campers: [
      Camper(
        name: 'Alex Rivera',
        phone: '(555) 201-4432',
        email: 'alex@example.com',
        role: 'Trip lead · Driver',
        emergencyContact: 'Maria Rivera (555) 201-9000',
      ),
      Camper(
        name: 'Jordan Lee',
        phone: '(555) 318-2210',
        email: 'jordan@example.com',
        role: 'Camp chef',
        emergencyContact: 'Chris Lee (555) 318-7788',
        notes: 'Vegetarian',
      ),
      Camper(
        name: 'Sam Patel',
        phone: '(555) 442-0917',
        email: 'sam@example.com',
        role: 'Fire & water',
      ),
      Camper(
        name: 'Riley Chen',
        phone: '(555) 660-3381',
        email: 'riley@example.com',
        role: 'Navigator · Driver',
        notes: 'Allergic to peanuts',
      ),
    ],
    meals: [
      Meal(
        day: 0,
        type: 'Dinner',
        title: 'Foil-packet fajitas',
        ingredients: ['Tortillas', 'Peppers', 'Onions', 'Chicken', 'Salsa'],
        cook: 'Jordan',
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
        cook: 'Alex',
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
        cook: 'Sam',
      ),
      Meal(
        day: 2,
        type: 'Breakfast',
        title: 'Breakfast burritos',
        ingredients: ['Eggs', 'Potatoes', 'Cheese', 'Tortillas'],
        cook: 'Riley',
      ),
    ],
    gear: [
      GearItem(
        name: '4-person tent',
        category: 'Shelter',
        bringer: 'Alex',
        packed: true,
      ),
      GearItem(
        name: 'Rain fly & stakes',
        category: 'Shelter',
        bringer: 'Alex',
        packed: true,
      ),
      GearItem(name: 'Pop-up canopy', category: 'Shelter', bringer: 'Sam'),
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
        bringer: 'Jordan',
        packed: true,
      ),
      GearItem(
        name: 'Cast iron skillet',
        category: 'Kitchen',
        bringer: 'Jordan',
      ),
      GearItem(
        name: 'Cooler',
        category: 'Kitchen',
        quantity: 2,
        bringer: 'Sam',
      ),
      GearItem(name: 'Water jugs (5 gal)', category: 'Kitchen', quantity: 2),
      GearItem(name: 'Rain jackets', category: 'Clothing'),
      GearItem(name: 'Warm layers', category: 'Clothing'),
      GearItem(
        name: 'First aid kit',
        category: 'Safety',
        bringer: 'Riley',
        packed: true,
      ),
      GearItem(name: 'Headlamps', category: 'Safety', quantity: 4),
      GearItem(name: 'Bear-proof food bin', category: 'Safety'),
      GearItem(name: 'Hatchet', category: 'Tools', bringer: 'Sam'),
      GearItem(name: 'Multi-tool', category: 'Tools'),
      GearItem(name: 'Sunscreen & bug spray', category: 'Personal'),
      GearItem(name: 'Card games', category: 'Fun', bringer: 'Riley'),
    ],
    activities: [
      Activity(
        day: 0,
        title: 'Set up camp & gather firewood',
        kind: 'Camp',
        time: '3:00 PM',
      ),
      Activity(
        day: 1,
        title: 'Pfeiffer Falls & Valley View',
        kind: 'Hike',
        time: '8:30 AM',
        location: 'Trailhead near the lodge',
        distance: '2.0 mi · 600 ft gain',
        notes: 'Bring water and snacks. Easy-moderate.',
      ),
      Activity(
        day: 1,
        title: 'McWay Falls overlook',
        kind: 'Day trip',
        time: '1:00 PM',
        location: 'Julia Pfeiffer Burns SP (15 min south)',
        distance: '0.6 mi round trip',
        notes: 'Day-use parking \$10. Great for photos.',
      ),
      Activity(
        day: 1,
        title: 'Sunset at Pfeiffer Beach',
        kind: 'Sightseeing',
        time: '6:15 PM',
        location: 'Sycamore Canyon Rd',
        notes: 'Narrow road – no trailers. Look for the keyhole arch.',
      ),
      Activity(
        day: 2,
        title: 'Big Sur River swim',
        kind: 'Water',
        time: '10:00 AM',
        location: 'River access by Loop B',
      ),
    ],
  );
}
