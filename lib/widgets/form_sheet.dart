import 'package:flutter/material.dart';

/// Describes one input on a [showFormSheet].
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.initial = '',
    this.hint,
    this.options,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.icon,
  });

  final String key;
  final String label;
  final String initial;
  final String? hint;

  /// When set, the field renders as a dropdown of these values.
  final List<String>? options;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final IconData? icon;
}

/// Shows a bottom sheet with a form built from [fields]. Resolves to the
/// entered values keyed by [FieldSpec.key], or null if dismissed.
Future<Map<String, String>?> showFormSheet(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String submitLabel = 'Save',
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<Map<String, String>>(
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
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      if (f.options == null) f.key: TextEditingController(text: f.initial),
  };
  late final Map<String, String> _choices = {
    for (final f in widget.fields)
      if (f.options != null)
        f.key: f.options!.contains(f.initial) ? f.initial : f.options!.first,
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      for (final e in _controllers.entries) e.key: e.value.text.trim(),
      ..._choices,
    });
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
              if (f.options != null)
                DropdownButtonFormField<String>(
                  initialValue: _choices[f.key],
                  decoration: InputDecoration(
                    labelText: f.label,
                    prefixIcon: f.icon == null ? null : Icon(f.icon),
                  ),
                  items: [
                    for (final o in f.options!)
                      DropdownMenuItem(value: o, child: Text(o)),
                  ],
                  onChanged: (v) => _choices[f.key] = v ?? f.options!.first,
                )
              else
                TextFormField(
                  controller: _controllers[f.key],
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
                  validator: f.required
                      ? (v) => (v == null || v.trim().isEmpty)
                            ? '${f.label} is required'
                            : null
                      : null,
                ),
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
