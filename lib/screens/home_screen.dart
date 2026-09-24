import 'package:flutter/material.dart';

import '../models.dart';
import '../sample_data.dart';
import '../util.dart';
import '../widgets/form_sheet.dart';
import 'trip_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _newTrip(BuildContext context) async {
    final store = StoreScope.of(context);
    final values = await showFormSheet(
      context,
      title: 'New trip',
      submitLabel: 'Choose dates',
      fields: const [
        FieldSpec.text(
          'name',
          'Trip name',
          hint: 'e.g. Yosemite Labor Day',
          required: true,
          icon: Icons.flag_outlined,
        ),
        FieldSpec.text(
          'campground',
          'Campground',
          hint: 'e.g. Upper Pines',
          icon: Icons.forest_outlined,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await pickTripDates(
      context,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 3)),
      initial: DateTimeRange(
        start: today.add(const Duration(days: 14)),
        end: today.add(const Duration(days: 16)),
      ),
    );
    if (range == null || !context.mounted) return;
    final trip = newTrip(
      name: values.str('name'),
      campground: values.str('campground'),
      start: range.start,
      end: range.end,
    );
    store.addTrip(trip);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TripScreen(tripId: trip.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final trips = [...store.trips]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final now = DateTime.now();
    final upcoming = trips
        .where((t) => t.daysUntil(now) > -t.dayCount)
        .toList();
    final past = trips.where((t) => t.daysUntil(now) <= -t.dayCount).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Row(
              children: [
                Icon(
                  Icons.landscape_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(width: 10),
                const Text('Basecamp'),
              ],
            ),
          ),
          if (trips.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onCreate: () => _newTrip(context)),
            ),
          if (upcoming.isNotEmpty) ...[
            _header(context, 'Upcoming trips'),
            _tripList(upcoming),
          ],
          if (past.isNotEmpty) ...[
            _header(context, 'Past trips'),
            _tripList(past),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newTrip(context),
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
    );
  }

  Widget _header(BuildContext context, String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    sliver: SliverToBoxAdapter(
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _tripList(List<Trip> trips) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverList.separated(
      itemCount: trips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) => TripCard(trip: trips[i]),
    ),
  );
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = trip.daysUntil(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: trip.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripBanner(trip: trip, compact: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fmtRange(trip.startDate, trip.endDate),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        countdownLabel(days, trip.dayCount),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: trip.packedFraction,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.gear.isEmpty
                        ? 'No gear listed yet'
                        : '${trip.packedCount} of ${trip.gear.length} items packed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _Stat(Icons.group_outlined, '${trip.campers.length}'),
                      _Stat(Icons.restaurant_outlined, '${trip.meals.length}'),
                      _Stat(Icons.hiking, '${trip.activities.length}'),
                      _Stat(Icons.payments_outlined, fmtMoney(trip.totalCost)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Illustrated header with the trip name, drawn in code so it needs no assets.
class TripBanner extends StatelessWidget {
  const TripBanner({super.key, required this.trip, this.compact = false});

  final Trip trip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: compact ? 120 : 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MountainPainter(seed: trip.name.hashCode)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black38),
                    ],
                  ),
                ),
                if (trip.campground.isNotEmpty)
                  Text(
                    trip.campground,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .92),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  _MountainPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2B266), Color(0xFFE07A4F), Color(0xFF7A5A8C)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final shift = (seed % 100) / 100.0;
    canvas.drawCircle(
      Offset(w * (0.2 + shift * 0.6), h * 0.38),
      h * 0.16,
      Paint()..color = const Color(0xFFFFE3B0),
    );

    void ridge(Color color, List<double> peaks, double base) {
      final path = Path()..moveTo(0, h);
      for (var i = 0; i < peaks.length; i++) {
        path.lineTo(w * i / (peaks.length - 1), h * peaks[i]);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    ridge(const Color(0xFF6B5B7B), [0.55, 0.3, 0.5, 0.25, 0.45, 0.35, 0.6], 0);
    ridge(const Color(0xFF3F5E55), [0.7, 0.55, 0.65, 0.45, 0.6, 0.5, 0.68], 0);

    // Tree line.
    final trees = Paint()..color = const Color(0xFF1F3B30);
    final path = Path()..moveTo(0, h);
    const count = 22;
    for (var i = 0; i <= count; i++) {
      final x = w * i / count;
      final tall = ((i * 7 + seed) % 5) / 5.0;
      path
        ..lineTo(x - w / count / 2, h * 0.86)
        ..lineTo(x, h * (0.68 - tall * 0.1))
        ..lineTo(x + w / count / 2, h * 0.86);
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, trees);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), trees);

    // Darken the bottom so white text stays legible.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .45)],
          stops: const [0.4, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _MountainPainter old) => old.seed != seed;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forest_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Plan your first trip', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Keep meals, gear, activities and campsite details in one place.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New trip'),
          ),
        ],
      ),
    );
  }
}
