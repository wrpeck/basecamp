import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'store.dart';

/// Makes the [TripStore] available to the widget tree and rebuilds
/// dependents whenever it changes.
class StoreScope extends InheritedNotifier<TripStore> {
  const StoreScope({super.key, required TripStore store, required super.child})
    : super(notifier: store);

  static TripStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
String fmtWeekday(DateTime d) => _weekdays[d.weekday - 1];
String fmtDayLabel(DateTime d) => '${fmtWeekday(d)}, ${fmtDate(d)}';

String fmtRange(DateTime a, DateTime b) {
  if (a.year == b.year && a.month == b.month) {
    return '${fmtDate(a)} – ${b.day}, ${b.year}';
  }
  return '${fmtDate(a)} – ${fmtDate(b)}, ${b.year}';
}

String fmtMoney(double v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return '\$$whole.${parts[1]}';
}

/// Parses "12", "\$12.50" or "1,200.00"; null when there's no number.
double? parseMoney(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
  final v = double.tryParse(cleaned);
  return v == null || v < 0 ? null : v;
}

String countdownLabel(int days, int dayCount) {
  if (days > 1) return 'In $days days';
  if (days == 1) return 'Tomorrow';
  if (days == 0) return 'Starts today';
  if (-days < dayCount) return 'Happening now';
  return 'Completed';
}

Future<void> openUri(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('not handled');
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text('Couldn\'t open ${uri.scheme} link')),
    );
  }
}

void callNumber(BuildContext context, String phone) => openUri(
  context,
  Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')),
);

void textNumber(BuildContext context, String phone) => openUri(
  context,
  Uri(scheme: 'sms', path: phone.replaceAll(RegExp(r'[^\d+]'), '')),
);

void sendEmail(BuildContext context, String email) =>
    openUri(context, Uri(scheme: 'mailto', path: email));

void openMaps(BuildContext context, double lat, double lng) => openUri(
  context,
  Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
);

Future<void> copyText(BuildContext context, String text, String what) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(SnackBar(content: Text('$what copied')));
}

String fmtTime(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

/// Parses coordinates typed or pasted in common formats:
/// "36.2508, -121.7847", "36.2508 N 121.7847 W" or "36°15'03\"N 121°47'05\"W".
(double, double)? parseCoords(String text) {
  final token = RegExp(
    r'([-+−]?\d+(?:[.,]\d+)?)\s*°?\s*'
    r"(?:(\d+(?:[.,]\d+)?)\s*['′’]\s*)?"
    r'(?:(\d+(?:[.,]\d+)?)\s*(?:["″”]|'
    "''"
    r'|’’)\s*)?'
    r'([NSEWnsew])?',
  );
  double? num(String? s) => s == null
      ? null
      : double.tryParse(s.replaceAll(',', '.').replaceAll('−', '-'));
  final parts = token.allMatches(text).where((m) => m[1] != null).toList();
  final values = <(double, String?)>[];
  for (final m in parts) {
    var v = num(m[1])!;
    final sign = v.isNegative ? -1 : 1;
    v = v.abs() + (num(m[2]) ?? 0) / 60 + (num(m[3]) ?? 0) / 3600;
    values.add((v * sign, m[4]?.toUpperCase()));
  }
  if (values.length < 2) return null;
  double apply((double, String?) v) =>
      (v.$2 == 'S' || v.$2 == 'W') ? -v.$1.abs() : v.$1;
  var lat = apply(values[0]), lng = apply(values[1]);
  if (values[0].$2 == 'E' || values[0].$2 == 'W') (lat, lng) = (lng, lat);
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return (lat, lng);
}

String fmtCoord(double lat, double lng) {
  String one(double v, String pos, String neg) =>
      '${v.abs().toStringAsFixed(4)}° ${v >= 0 ? pos : neg}';
  return '${one(lat, 'N', 'S')}, ${one(lng, 'E', 'W')}';
}

IconData mealIcon(String type) => switch (type) {
  'Breakfast' => Icons.free_breakfast_outlined,
  'Lunch' => Icons.lunch_dining_outlined,
  'Dinner' => Icons.dinner_dining_outlined,
  _ => Icons.cookie_outlined,
};

IconData gearIcon(String category) => switch (category) {
  'Shelter' => Icons.cabin_outlined,
  'Sleep' => Icons.bedtime_outlined,
  'Kitchen' => Icons.soup_kitchen_outlined,
  'Clothing' => Icons.checkroom_outlined,
  'Safety' => Icons.health_and_safety_outlined,
  'Tools' => Icons.handyman_outlined,
  'Personal' => Icons.face_retouching_natural_outlined,
  'Fun' => Icons.sports_esports_outlined,
  _ => Icons.inventory_2_outlined,
};

IconData activityIcon(String kind) => switch (kind) {
  'Hike' => Icons.hiking,
  'Day trip' => Icons.directions_car_outlined,
  'Water Sports' => Icons.kayaking,
  'Biking' => Icons.directions_bike,
  'Climbing' => Icons.terrain_outlined,
  'Stargazing' => Icons.nights_stay_outlined,
  'Camp' => Icons.local_fire_department_outlined,
  'Sightseeing' => Icons.photo_camera_outlined,
  _ => Icons.explore_outlined,
};
