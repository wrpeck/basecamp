// Each FieldSpec constructor takes a precisely typed `initial` and stores it
// in the shared Object? field, which an initializing formal can't express.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../util.dart';

/// A value/label pair offered by choice and multi-select fields.
typedef Option = ({String value, String label});

List<Option> plainOptions(Iterable<String> values) => [
  for (final v in values) (value: v, label: v),
];

/// Value stored for the "everyone / anyone" chip of a multi-select.
const allValue = '*';

enum _Kind { text, choice, multi, time, toggle }

/// Describes one input on a [showFormSheet].
class FieldSpec {
  const FieldSpec.text(
    this.key,
    this.label, {
    String initial = '',
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.icon,
    this.validator,
  }) : _kind = _Kind.text,
       initial = initial,
       options = const [],
       allLabel = null;

  const FieldSpec.choice(
    this.key,
    this.label, {
    required this.options,
    String? initial,
    this.icon,
  }) : _kind = _Kind.choice,
       initial = initial,
       hint = null,
       keyboardType = null,
       maxLines = 1,
       required = false,
       validator = null,
       allLabel = null;

  /// Chips allowing several [options]. When [allLabel] is set, an extra chip
  /// stands for everyone and is exclusive with the rest.
  const FieldSpec.multi(
    this.key,
    this.label, {
    required this.options,
    List<String> initial = const [],
    this.allLabel,
    this.hint,
    this.icon,
  }) : _kind = _Kind.multi,
       initial = initial,
       keyboardType = null,
       maxLines = 1,
       required = false,
       validator = null;

  const FieldSpec.time(this.key, this.label, {int? initial, this.icon})
    : _kind = _Kind.time,
      initial = initial,
      options = const [],
      hint = null,
      keyboardType = null,
      maxLines = 1,
      required = false,
      validator = null,
      allLabel = null;

  const FieldSpec.toggle(
    this.key,
    this.label, {
    bool initial = false,
    this.hint,
    this.icon,
  }) : _kind = _Kind.toggle,
       initial = initial,
       options = const [],
       keyboardType = null,
       maxLines = 1,
       required = false,
       validator = null,
       allLabel = null;

  final _Kind _kind;
  final String key;
  final String label;
  final Object? initial;
  final String? hint;
  final List<Option> options;
  final String? allLabel;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final IconData? icon;
  final String? Function(String value)? validator;
}

/// Values entered on a form sheet: text and choice fields give a String,
/// multi fields a `List<String>`, time fields an `int?` of minutes and
/// toggles a `bool`.
typedef FormValues = Map<String, Object?>;

extension FormValuesX on FormValues {
  String str(String key) => this[key] as String;
  List<String> list(String key) => this[key] as List<String>;
  int? time(String key) => this[key] as int?;
  bool flag(String key) => this[key] as bool;
}

/// Shows a bottom sheet with a form built from [fields]. Resolves to the
/// entered values keyed by [FieldSpec.key], or null if dismissed.
Future<FormValues?> showFormSheet(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String submitLabel = 'Save',
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<FormValues>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FormSheet(
      title: title,
      fields: fields,
      submitLabel: submitLabel,
      onDelete: onDelete,
    ),
  );
}

class _FormSheet extends StatefulWidget {
  const _FormSheet({
    required this.title,
    required this.fields,
    required this.submitLabel,
    this.onDelete,
  });

  final String title;
  final List<FieldSpec> fields;
  final String submitLabel;
  final VoidCallback? onDelete;

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields)
      if (f._kind == _Kind.text)
        f.key: TextEditingController(text: f.initial as String),
  };
  late final FormValues _values = {
    for (final f in widget.fields)
      if (f._kind == _Kind.choice)
        f.key: f.options.any((o) => o.value == f.initial)
            ? f.initial
            : f.options.first.value
      else if (f._kind == _Kind.multi)
        f.key: List<String>.of(f.initial as List<String>)
      else if (f._kind != _Kind.text)
        f.key: f.initial,
  };

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, Object?>{
      for (final e in _text.entries) e.key: e.value.text.trim(),
      ..._values,
    });
  }

  Widget _field(FieldSpec f) {
    final theme = Theme.of(context);
    switch (f._kind) {
      case _Kind.text:
        return TextFormField(
          controller: _text[f.key],
          keyboardType: f.maxLines > 1
              ? TextInputType.multiline
              : f.keyboardType,
          maxLines: f.maxLines,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: f.label,
            hintText: f.hint,
            prefixIcon: f.icon == null ? null : Icon(f.icon),
          ),
          validator: (raw) {
            final v = (raw ?? '').trim();
            if (f.required && v.isEmpty) return '${f.label} is required';
            if (v.isNotEmpty && f.validator != null) return f.validator!(v);
            return null;
          },
        );
      case _Kind.choice:
        return DropdownButtonFormField<String>(
          initialValue: _values[f.key] as String,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: f.label,
            prefixIcon: f.icon == null ? null : Icon(f.icon),
          ),
          items: [
            for (final o in f.options)
              DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
          onChanged: (v) => _values[f.key] = v ?? f.options.first.value,
        );
      case _Kind.multi:
        final selected = _values[f.key] as List<String>;
        final all = selected.contains(allValue);
        void toggle(String value, bool on) => setState(() {
          if (value == allValue) {
            selected.clear();
            if (on) selected.add(allValue);
          } else {
            selected.remove(allValue);
            on ? selected.add(value) : selected.remove(value);
          }
        });
        return InputDecorator(
          decoration: InputDecoration(
            labelText: f.label,
            helperText: f.hint,
            helperMaxLines: 2,
            prefixIcon: f.icon == null ? null : Icon(f.icon),
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          ),
          child: f.options.isEmpty && f.allLabel == null
              ? Text(
                  'Add people on the Crew tab first',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (f.allLabel != null)
                      FilterChip(
                        label: Text(f.allLabel!),
                        selected: all,
                        onSelected: (on) => toggle(allValue, on),
                      ),
                    for (final o in f.options)
                      FilterChip(
                        label: Text(o.label),
                        selected: selected.contains(o.value),
                        onSelected: (on) => toggle(o.value, on),
                      ),
                  ],
                ),
        );
      case _Kind.time:
        final minutes = _values[f.key] as int?;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: minutes == null
                  ? const TimeOfDay(hour: 9, minute: 0)
                  : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
            );
            if (picked != null) {
              setState(() => _values[f.key] = picked.hour * 60 + picked.minute);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: f.label,
              prefixIcon: Icon(f.icon ?? Icons.schedule),
              suffixIcon: minutes == null
                  ? const Icon(Icons.arrow_drop_down)
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _values[f.key] = null),
                    ),
            ),
            child: Text(
              minutes == null ? 'Not set' : fmtTime(minutes),
              style: minutes == null
                  ? TextStyle(color: theme.colorScheme.outline)
                  : null,
            ),
          ),
        );
      case _Kind.toggle:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            value: _values[f.key] as bool,
            onChanged: (v) => setState(() => _values[f.key] = v),
            secondary: f.icon == null ? null : Icon(f.icon),
            title: Text(f.label),
            subtitle: f.hint == null ? null : Text(f.hint!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final f in widget.fields) ...[
              _field(f),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String action = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Date range picker with an explicit close button and Done action, so it is
/// easy to dismiss on phones.
Future<DateTimeRange?> pickTripDates(
  BuildContext context, {
  required DateTimeRange initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDateRangePicker(
    context: context,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    initialDateRange: initial,
    helpText: 'Trip dates',
    saveText: 'Done',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
}
