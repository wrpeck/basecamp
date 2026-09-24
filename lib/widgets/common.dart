import 'package:flutter/material.dart';

import '../models.dart';
import 'form_sheet.dart';

class SectionCard extends StatefulWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onEdit,
    this.onHeaderTap,
    this.trailing,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onEdit;

  /// Called when the header row is tapped. Defaults to [onEdit], or to
  /// toggling the section when [collapsible].
  final VoidCallback? onHeaderTap;
  final Widget? trailing;

  /// Lets the user fold the section away by tapping its header.
  final bool collapsible;
  final bool initiallyExpanded;

  /// Short text shown next to the title, e.g. an item count.
  final String? badge;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = !widget.collapsible || _expanded;
    final onTap = widget.collapsible
        ? () => setState(() => _expanded = !_expanded)
        : widget.onHeaderTap ?? widget.onEdit;
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 8, expanded ? 16 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.badge!,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?widget.trailing,
                  if (widget.onEdit != null)
                    IconButton(
                      tooltip: 'Edit ${widget.title}',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: widget.onEdit,
                    )
                  else if (widget.collapsible)
                    IconButton(
                      tooltip: _expanded ? 'Collapse' : 'Expand',
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more),
                      ),
                      onPressed: onTap,
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8),
                      child: widget.child,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks gear as belonging to someone's own list or to the group.
class ScopeTag extends StatelessWidget {
  const ScopeTag({super.key, required this.personal, this.owner});

  final bool personal;

  /// Whose personal list, when it isn't the viewer's.
  final String? owner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = personal
        ? (owner == null ? 'MINE' : owner!.toUpperCase())
        : 'GROUP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: personal ? scheme.secondaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: personal
              ? scheme.onSecondaryContainer
              : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.actions = const [],
    this.placeholder = 'Not set',
  });

  final String label;
  final String value;
  final List<Widget> actions;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? placeholder : value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: empty ? theme.colorScheme.outline : null,
                    fontStyle: empty ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
          if (!empty) ...actions,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Centered in whatever space the parent gives it, and still scrollable
    // when that space is short (e.g. with the keyboard up).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 20), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day, required this.label});

  final int day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Day ${day + 1}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Crew members as options for choice and multi-select fields.
List<Option> camperOptions(Trip trip) => [
  for (final c in trip.campers) (value: c.id, label: c.firstName),
];

/// "Everyone", "Anyone" or a list of first names for display.
String namesOr(Trip trip, List<String> ids, String fallback) {
  final names = trip.names(ids);
  return names.isEmpty ? fallback : names.join(', ');
}

/// How to refer to a camper in sentences: "you" for me, else a first name.
String who(Trip trip, String id, {bool capitalize = false}) {
  final c = trip.camper(id);
  if (c == null) return '?';
  if (c.isMe) return capitalize ? 'You' : 'you';
  return c.firstName;
}
